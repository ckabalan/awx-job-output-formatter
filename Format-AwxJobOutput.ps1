<#

.SYNOPSIS
Formats and Fixes AWX / Ansible Tower Job Outputs

.DESCRIPTION
This tool takes a job output file (`job_#####.txt`) and performs the following:
  - Re-combines tasks into one task heading if they were fragmented (such as when using `strategy: free` in a playbook)
    - Move all "included" events into the header
    - Sorts the events under each section by server name
  - Allows filtering based on system name

By default outputs the corrected file to filename_FORMATTED.ext (no -SystemName parameter) or filename_SystemName.ext (with -SystemName parameter).

.PARAMETER JobOutput
The Job Events file to be processed. Can be obtained by clicking the "Download Output" button on the Job Details page for a completed job

.PARAMETER SystemName
Only output events related to this server.

.PARAMETER Inplace
Modify the JobOutput file in-place.

.PARAMETER NoSort
Do not sort events within each task.

.EXAMPLE
Format-AwsJobOutput job_12345.txt

This command re-combines all Ansible tasks from all servers into their respective task heading.

.EXAMPLE
Format-AwsJobOutput job_12345.txt -SystemName SERVER1

This command additionally limits the output to only events related to SERVER1.

.EXAMPLE
Format-AwsJobOutput job_12345.txt -SystemName SERVER1 -Inplace

Same as the above but replaces the contents of the original input file with the output.

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
		$SystemName,
		[parameter(Mandatory=$false)]
		[Switch]
		$Inplace=$false,
		[parameter(Mandatory=$false)]
		[Switch]
		$NoSort=$false
	)
	$JobLog = Get-Content $JobOutput

	if ($Inplace) {
		$OutputFilename = $JobOutput
	} elseif ($SystemName) {
		$Temp = Get-Item $JobOutput
		$OutputFilename = $Temp.DirectoryName + [IO.Path]::DirectorySeparatorChar + $Temp.Basename + '_' + $SystemName + $Temp.Extension
	} else {
		$Temp = Get-Item $JobOutput
		$OutputFilename = $Temp.DirectoryName + [IO.Path]::DirectorySeparatorChar + $Temp.Basename + '_FORMATTED' + $Temp.Extension
	}
	$ParsedData = [ordered]@{'HEADER' = @()}
	$Section = 'HEADER'
	ForEach ($Line in $JobLog) {
		if ($Line.Length -eq 0) { continue }
		$AddLine = $false
		$LineServerName = 'UNKNOWN'
		if ($Line -match '^(?:(?:.+): \[(.+)\](?: => .+)?)?(?:included: (?:.+) for (.+))?(?:([^\s]+)\s+: ok=\d+\s+changed=\d+\s+unreachable=\d+\s+failed=\d+\s+)?$') {
			$Matches.Remove(0)
			$LineServerName = ($Matches.Values.Where({ $_ -ne "" }))[0].ToUpper()
		}
		if ($SystemName) {
			if ($LineServerName -ne 'UNKNOWN') {
				$TempSystemName = $SystemName.ToUpper()
				Write-Host $LineServerName
				if ($LineServerName -match $TempSystemName) {
					$AddLine = $true
				}
			} else {
				$AddLine = $true
			}
		} else {
			$AddLine = $true
		}
		if ($AddLine) {
			if (
				($Line -match 'PLAY \[.+\] \*\*\*+') -or
				($Line -match 'TASK \[.+\] \*\*\*+') -or
				($Line -match 'PLAY RECAP \*\*\*+')
			) {
				$Section = $Line
				if (-not $ParsedData.Contains($Section)) {
					$ParsedData.Add($Section, @($Line))
				}
				continue
			}
			if ($Line.substring(0, 8) -eq 'included') {
				# Move the includeds to the header since they're ALWAYS out of place
				$ParsedData['HEADER'] += $Line
			} else {
				# All other lines get added to the most recent section found
				$ParsedData[$Section] += $Line
			}
		}
	}

	$FinalContent = @()

	ForEach ($Section in $ParsedData.Keys) {
		if ($Section -eq 'HEADER') {
			$Lines = $ParsedData[$Section]
		} else {
			# Print the Section Name
			$FinalContent += $ParsedData[$Section][0]
			$Lines = $ParsedData[$Section] | Select-Object -Skip 1
			if ($NoSort -eq $false) {
				# Sort all the remaining lines by server name for consistency
				if ($Section.Substring(0, 4) -eq 'TASK') {
					# For TASK sections
					$Lines = $Lines | Sort-Object @{Expression={
						# TODO: Refactor to match functionality from SystemName filter
						if ($_ -match '(?<Status>.+): \[(?<ServerName>.+)\]( => .+)?$') {
							$Matches.ServerName
						}
					}; Ascending=$true}
				} else {
					# For PLAY and PLAY RECAP sections 
					$Lines = $Lines | Sort-Object
				}
			}
		}
		# Print all server entries sorted
		$FinalContent += $Lines
		# Blank line before the next section
		$FinalContent += ''
	}
	$($FinalContent -Join "`n") | Out-File $OutputFilename
}