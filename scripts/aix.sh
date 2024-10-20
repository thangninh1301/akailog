---
- name: Ping hosts and check HTTPS connectivity, generate CSV with results
  hosts: all  # Target all hosts in the inventory
  gather_facts: no
  vars:
    temp_dir: "{{ ansible_env.TEMP | default(ansible_env.TMPDIR | default('/tmp')) }}"
    csv_file_path: "{{ temp_dir }}/ping_https_result_{{ lookup('pipe', 'date +%Y%m%d') }}.csv"
    nexus_url: "http://nexus.example.com/repository/your-repo/"
    nexus_username: "your_username"
    nexus_password: "your_password"
    results: []  # Initialize an empty list for results

  tasks:
    - name: Ensure the temporary directory exists
      file:
        path: "{{ temp_dir }}"
        state: directory
        mode: '0755'  # Set appropriate permissions

    - name: Ping the host
      shell: "ping -c 2 {{ inventory_hostname }} > /dev/null 2>&1"
      register: ping_result
      ignore_errors: yes

    - name: Set ping status
      set_fact:
        ping_status: "{{ 'Success' if ping_result.rc == 0 else 'Fail' }}"

    - name: Check HTTPS connectivity if ping is successful
      uri:
        url: "https://{{ inventory_hostname }}"
        method: GET
        return_content: no
        timeout: 10  # Adjust as necessary
      register: https_check_result
      when: ping_status == 'Success'
      ignore_errors: yes

    - name: Set HTTPS status
      set_fact:
        https_status: "{{ 'Success' if https_check_result.status == 200 else 'Fail' }}"
      when: ping_status == 'Success'

    - name: Collect results
      set_fact:
        results: "{{ results + [{'ip_address': inventory_hostname, 'ping_status': ping_status, 'https_status': https_status | default('Not Checked')} ] }}"

    - name: Generate CSV file with ping and HTTPS check results
      copy:
        dest: "{{ csv_file_path }}"
        content: |
          IP Address, Ping Status, HTTPS Status
          {% for result in results %}
          {{ result.ip_address }}, {{ result.ping_status }}, {{ result.https_status }}
          {% endfor %}
      when: results | length > 0

    - name: Check if CSV file exists
      stat:
        path: "{{ csv_file_path }}"
      register: csv_file_stat

    - name: Print CSV file contents if it exists
      command: cat {{ csv_file_path }}
      when: csv_file_stat.stat.exists
      register: csv_file_contents

    - name: Debug CSV file contents
      debug:
        msg: "{{ csv_file_contents.stdout }}"
      when: csv_file_stat.stat.exists

    - name: Upload CSV file to Nexus
      uri:
        url: "{{ nexus_url }}ping_https_result_{{ lookup('pipe', 'date +%Y%m%d') }}.csv"
        method: PUT
        user: "{{ nexus_username }}"
        password: "{{ nexus_password }}"
        src: "{{ csv_file_path }}"
        headers:
          Content-Type: "text/csv"
        force_basic_auth: yes
      when: csv_file_stat.stat.exists
