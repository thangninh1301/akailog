---
name: Create jobs for Linux, AIX, and Windows hosts
hosts: all
become: yes
tasks:

  # Block for Linux hosts (RHEL)
  - name: "Push base script job on Linux hosts"
    block:
      - name: "Push base script from Ansible to RHEL"
        copy:
          src: scripts/
          dest: "{{ path_job }}/scripts"
        when: ansible_os_family == "RedHat" and ansible_connection == 'ssh'

      - name: "Ensure set permissions of all script files to 755 (Linux)"
        file:
          path: "{{ path_job }}/scripts"
          state: directory
          mode: '0755'
          recurse: yes
        when: ansible_os_family == "RedHat" and ansible_connection == 'ssh'

      - name: "Push Linux log manager source script"
        template:
          src: templates/source_linux.j2
          dest: "{{ path_job }}/source_linux.sh"
          mode: '0755'
        when: ansible_os_family == "RedHat" and ansible_connection == 'ssh'

  # Block for AIX hosts
  - name: "Push base script job on AIX hosts"
    block:
      - name: "Push base script from Ansible to AIX"
        copy:
          src: scripts/
          dest: "{{ path_job }}/scripts"
        when: ansible_os_family == "AIX" and ansible_connection == 'ssh'

      - name: "Ensure set permissions of all script files to 755 (AIX)"
        file:
          path: "{{ path_job }}/scripts"
          state: directory
          mode: '0755'
          recurse: yes
        when: ansible_os_family == "AIX" and ansible_connection == 'ssh'

      - name: "Push AIX log manager source script"
        template:
          src: templates/source_aix.j2
          dest: "{{ path_job }}/source_aix.sh"
          mode: '0755'
        when: ansible_os_family == "AIX" and ansible_connection == 'ssh'

  # Block for Windows hosts
  - name: "Push base script job on Windows hosts"
    block:
      - name: "Push base script from Ansible to Windows"
        win_copy:
          src: scripts/
          dest: "{{ path_job }}\scripts"
        when: ansible_connection == 'winrm'

      - name: "Ensure set permissions of all script files (Windows)"
        win_acl:
          path: "{{ path_job }}\scripts"
          rights:
            - perm: 'full'
              principal: 'Everyone'
        when: ansible_connection == 'winrm'

      - name: "Push Windows log manager source script"
        template:
          src: templates/source_windows.j2
          dest: "{{ path_job }}\source_windows.ps1"
        when: ansible_connection == 'winrm'
