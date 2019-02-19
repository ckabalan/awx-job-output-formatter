<#

.SYNOPSIS
Formats and Fixes AWX / Ansible Tower Job Outputs

.DESCRIPTION
This tool takes a job output file (`job_#####.txt`) and performs the following:
   - Re-combines tasks into one task heading if they were fragmented (such as when using `strategy: free` in a playbook)
   - Allows filtering based on system name

.EXAMPLE
Format-AwsJobOutput job_12345.txt

This command re-combines all Ansible tasks from all servers into their respective task heading.

.EXAMPLE
Format-AwsJobOutput job_12345.txt -SystemName SERVER1

This command additionally limits the output to only events related to SERVER1.

.NOTES
Format-AwxJobOutput is released under the MIT License (https://opensource.org/licenses/MIT).

.LINK
https://github.com/ckabalan/awx-job-output-formatter

#>

Function Format-AwxJobOutput {
	Param(
		[parameter(Mandatory=$true,Position=0)]
		[String]
		$JobOutput,
		[parameter(Mandatory=$false,Position=1)]
		[String]
		$SystemName
	)
	Write-Host Hello World!
}