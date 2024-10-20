---
- name: Ping domains and generate CSV with results
  hosts: localhost
  gather_facts: no
  vars:
    domains_to_ping:  # List of domains to ping, passed in as a variable or from extra vars
      - example.com
      - google.com
      - nonexistingdomain.com
    csv_file_path: "/tmp/ping_result_{{ lookup('pipe', 'date +%Y%m%d') }}.csv"
    nexus_url: "http://nexus.example.com/repository/your-repo/"
    nexus_username: "your_username"
    nexus_password: "your_password"
  tasks:
    - name: Ping each domain (Linux/Unix)
      shell: "ping -c 2 {{ item }} > /dev/null 2>&1"
      register: ping_result
      with_items: "{{ domains_to_ping }}"
      ignore_errors: yes

    - name: Add successful pings to list
      set_fact:
        successful_pings: "{{ successful_pings | default([]) + [item.item] }}"
      when: ping_result.results[item.ansible_loop_var].rc == 0
      with_items: "{{ ping_result.results }}"

    - name: Add failed pings to list
      set_fact:
        failed_pings: "{{ failed_pings | default([]) + [item.item] }}"
      when: ping_result.results[item.ansible_loop_var].rc != 0
      with_items: "{{ ping_result.results }}"

    - name: Ensure /tmp/ directory exists for the CSV file
      file:
        path: /tmp/
        state: directory

    - name: Generate CSV file with ping results
      copy:
        dest: "{{ csv_file_path }}"
        content: |
          Domain, Status
          {% for domain in successful_pings %}{{ domain }}, Success
          {% endfor %}
          {% for domain in failed_pings %}{{ domain }}, Fail
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
