# AWS / Ansible Tower Job Output Formatter

This tool takes a job output file (`job_#####.txt`) and performs the following:

- Re-combines tasks into one task heading if they were fragmented (such as when using `strategy: free` in a playbook)
- Allows filtering based on system name