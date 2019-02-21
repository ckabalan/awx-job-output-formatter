# Format-AwxJobOutput

Formats and Fixes AWX / Ansible Tower Job Outputs

## Description

This tool takes a job output file (`job_#####.txt`) and performs the following:
  - Re-combines tasks into one task heading if they were fragmented (such as when using `strategy: free` in a playbook)
    - Moves all "included" events into the header
    - Sorts the events under each section by server name
  - Allows filtering based on system name

By default outputs the corrected file to filename_FORMATTED.ext (no -SystemName parameter) or filename_SystemName.ext (with -SystemName parameter).

Fully supports `Get-Help Format-AwxJobOutput`.

## How to Use

When starting a PowerShell session load the function by running `Import-Module .\Path\To\Format-AwxJobOutput.psm1` and then viewing the help with `Get-Help Format-AwxJobOutput`.

To install and autoload permanently:
- Install `Format-AwxJobOutput` as a module: 
  - In the same directory as your PowerShell `$profile` script there should be a `Modules` folder
    - Windows PowerShell Default: `C:\Users\USERNAME\Documents\WindowsPowerShell\Modules\`
    - PowerShell Core Default: `C:\Users\USERNAME\Documents\PowerShell\Modules\`
  - Inside the `Modules` folder create a folder named `Format-AwxJobOutput`
  - Save `Format-AwxJobOutput.psm1` within `Modules\Format-AwxJobOutput\`
- Autoload the `Format-AwxJobOutput` on PowerShall Start:
  - Edit or Create your PowerShell `$profile` script:
    - Windows PowerShell Default: `C:\Users\USERNAME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`
    - PowerShell Core Default: `C:\Users\USERNAME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
  - Add the line `Import-Module Format-AwxJobOutput`
- Launch a new PowerShell session and make sure `Get-Help Format-AwxJobOutput` works.

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