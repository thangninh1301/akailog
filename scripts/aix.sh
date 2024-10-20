---
- name: Check ping and HTTPS connectivity for inventory hosts and generate a single CSV report
  hosts: all  # Run on all hosts in the inventory
  gather_facts: no
  vars:
    csv_file_path: "/tmp/ping_https_result_{{ lookup('pipe', 'date +%Y%m%d') }}.csv"  # Set the CSV file path
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
        results: "{{ results + [{'ip_address': hostvars[inventory_hostname]['ansible_host'], 'hostname': inventory_hostname, 'ping_status': ping_status, 'https_status': https_status | default('Not Checked')} ] }}"

  # After collecting all results from all hosts, generate the CSV file
  - name: Generate CSV file with results
    copy:
      dest: "{{ csv_file_path }}"
      content: |
        IP Address, Hostname, Ping Status, HTTPS Status
        {% for result in results %}
        {{ result.ip_address }}, {{ result.hostname }}, {{ result.ping_status }}, {{ result.https_status }}
        {% endfor %}
    when: results | length > 0
    delegate_to: localhost  # Ensure the file is created on the Ansible control machine

  - name: Display the path of the generated CSV file
    debug:
      msg: "CSV file saved at: {{ csv_file_path }}"

  - name: Read the generated CSV file
    slurp:
      src: "{{ csv_file_path }}"
    register: csv_file_content

  - name: Display the content of the generated CSV file
    debug:
      msg: "{{ csv_file_content.content | b64decode }}"
    when: csv_file_content is defined


    current_content=$(head -n -1 "$result_path")

# Write back the current content without the last line
printf "%s" "$current_content" > "$result_path"

# Append the desired content to the file
echo ",{{ leader_PIC }},{{ job_name }},{{ service.name }}" >> "$result_path"


  - name: Write results to CSV file using echo
    shell: |
      echo "IP Address,Hostname,Ping Status,HTTPS Status" > "{{ csv_file_path }}"
      {% for result in results %}
      echo "{{ result.ip_address }},{{ result.hostname }},{{ result.ping_status }},{{ result.https_status }}" >> "{{ csv_file_path }}"
      {% endfor %}
    when: results | length > 0
    delegate_to: localhost  # Ensure the file is created on the Ansible control machine

