---
- name: Check ping connectivity for Windows, RHEL, and AIX hosts
  hosts: all
  gather_facts: no
  vars:
    csv_file_path: "/tmp/ping_result_{{ lookup('pipe', 'date +%Y%m%d') }}.csv"
    nexus_url: "http://nexus.example.com/repository/your-repo/"
    nexus_username: "your_username"
    nexus_password: "your_password"
  tasks:
    - name: Ping Windows hosts
      win_ping:
      when: ansible_connection == "winrm"
      register: win_ping_result

    - name: Ping Linux (RHEL/AIX) hosts
      ping:
      when: ansible_connection == "ssh"
      register: linux_ping_result

    - name: Add successful Windows ping results to list
      set_fact:
        successful_pings: "{{ successful_pings | default([]) + [ansible_host] }}"
      when: win_ping_result.ping == "pong"

    - name: Add failed Windows ping results to list
      set_fact:
        failed_pings: "{{ failed_pings | default([]) + [ansible_host] }}"
      when: win_ping_result.ping != "pong"

    - name: Add successful Linux ping results to list
      set_fact:
        successful_pings: "{{ successful_pings | default([]) + [ansible_host] }}"
      when: linux_ping_result.ping == "pong"

    - name: Add failed Linux ping results to list
      set_fact:
        failed_pings: "{{ failed_pings | default([]) + [ansible_host] }}"
      when: linux_ping_result.ping != "pong"

    - name: Ensure /tmp/ directory exists for the CSV file
      file:
        path: /tmp/
        state: directory

    - name: Generate CSV file with ping results
      copy:
        dest: "{{ csv_file_path }}"
        content: |
          IP, Status
          {% for ip in successful_pings %}{{ ip }}, Success
          {% endfor %}
          {% for ip in failed_pings %}{{ ip }}, Fail
          {% endfor %}

    - name: Upload CSV file to Nexus
      uri:
        url: "{{ nexus_url }}ping_result_{{ lookup('pipe', 'date +%Y%m%d') }}.csv"
        method: PUT
        user: "{{ nexus_username }}"
        password: "{{ nexus_password }}"
        src: "{{ csv_file_path }}"
        headers:
          Content-Type: "text/csv"
        force_basic_auth: yes
      when: successful_pings is defined or failed_pings is defined
