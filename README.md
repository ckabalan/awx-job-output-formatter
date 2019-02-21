# Format-AwxJobOutput

Formats and Fixes AWX / Ansible Tower Job Outputs

## Description

This tool takes a job output file (`job_#####.txt`) and performs the following:
  - Re-combines tasks into one task heading if they were fragmented (such as when using `strategy: free` in a playbook)
    - Move all "included" events into the header
    - Sorts the events under each section by server name
  - Allows filtering based on system name

By default outputs the corrected file to filename_FORMATTED.ext (no -SystemName parameter) or filename_SystemName.ext (with -SystemName parameter).

Fully support `Get-Help Format-AwxJobOutput`.

## Parameters

**-JobOutput [InputFilename]**

The Job Events file to be processed. Can be obtained by clicking the "Download Output" button on the Job Details page for a completed job

**-SystemName [NameToFilter]**

Only output events related to this server.

**-Inplace**

Modify the JobOutput file in-place.

**-NoSort**

Do not sort events within each task.

## Examples

`Format-AwxJobOutput job_12345.txt`

This command re-combines all Ansible tasks from all servers into their respective task heading.

`Format-AwxJobOutput job_12345.txt -SystemName SERVER1`

This command additionally limits the output to only events related to SERVER1.

`Format-AwxJobOutput job_12345.txt -SystemName SERVER1 -Inplace`

Same as the above but replaces the contents of the original input file with the output.

## License

Format-AwxJobOutput is released under the [MIT License](https://opensource.org/licenses/MIT)