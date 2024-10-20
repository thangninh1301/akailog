---
- name: Ping domains and check HTTPS connectivity, generate CSV with results
  hosts: localhost
  gather_facts: no
  vars:
    domain_to_check: "example.com"  # Single domain to check, passed in as a variable
    csv_file_path: "/tmp/ping_https_result_{{ lookup('pipe', 'date +%Y%m%d') }}.csv"
    nexus_url: "http://nexus.example.com/repository/your-repo/"
    nexus_username: "your_username"
    nexus_password: "your_password"
  tasks:
    - name: Ping the domain
      shell: "ping -c 2 {{ domain_to_check }} > /dev/null 2>&1"
      register: ping_result
      ignore_errors: yes

    - name: Set ping status
      set_fact:
        ping_status: "{{ 'Success' if ping_result.rc == 0 else 'Fail' }}"

    - name: Check HTTPS connectivity to the domain if ping is successful
      uri:
        url: "https://{{ domain_to_check }}"
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

    - name: Ensure /tmp/ directory exists for the CSV file
      file:
        path: /tmp/
        state: directory

    - name: Generate CSV file with ping and HTTPS check results
      copy:
        dest: "{{ csv_file_path }}"
        content: |
          Domain, Ping Status, HTTPS Status
          {{ domain_to_check }}, {{ ping_status }}, {{ https_status | default('Not Checked') }}

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
      when: ping_status is defined
