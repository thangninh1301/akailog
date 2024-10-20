---
- name: Check ping and HTTPS connectivity for inventory hosts and generate a single CSV report
  hosts: all  # Run on all hosts in the inventory
  gather_facts: no
  vars:
    csv_file_path: "/tmp/ping_https_result_{{ lookup('pipe', 'date +%Y%m%d') }}.csv"  # Set the CSV file path
    nexus_url: "http://nexus.example.com/repository/your-repo/"
    nexus_username: "your_username"
    nexus_password: "your_password"
    results: []  # Initialize an empty list to collect results

  tasks:
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

    - name: Wait for all tasks to complete (important to ensure all results are collected)
      meta: flush_handlers

    - name: Generate CSV file with results
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
