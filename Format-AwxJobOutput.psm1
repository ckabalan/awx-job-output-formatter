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
Format-AwxJobOutput job_12345.txt

This command re-combines all Ansible tasks from all servers into their respective task heading.

.EXAMPLE
Format-AwxJobOutput job_12345.txt -SystemName SERVER1

This command additionally limits the output to only events related to SERVER1.

.EXAMPLE
Format-AwxJobOutput job_12345.txt -SystemName SERVER1 -Inplace

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
	# Match the following lines extracting the following:
	# included: /var/lib/awx/path/file.yml for SERVER1, SERVER2, SERVER4
	# 		Extracts: SERVER1, SERVER2, SERVER4
	# included: /var/lib/awx/path/file.yml for SERVER3
	# 		Extracts: SERVER3
	# ok: [SERVER1]
	# 		Extracts: SERVER1
	# ok: [SERVER2] => {"module_name": {"key1": "value1", "key2": "value2"}, "changed": false}
	# 		Extracts: SERVER2
	# SERVER3                 : ok=67   changed=0    unreachable=0    failed=0   
	# 		Extracts: SERVER3
	$ServerNameExtractionRegex = '^(?:(?:.+): \[(.+)\](?:.+=> .+)?)?(?:included: (?:.+) for (.+))?(?:([^\s]+)\s+: ok=\d+\s+changed=\d+\s+unreachable=\d+\s+failed=\d+\s+)?$'

	$JobLog = Get-Content $JobOutput

	# Determine where to save the output
	if ($Inplace) {
		$OutputFilename = $JobOutput
	} elseif ($SystemName) {
		$Temp = Get-Item $JobOutput
		$OutputFilename = $Temp.DirectoryName + [IO.Path]::DirectorySeparatorChar + $Temp.Basename + '_' + $SystemName + $Temp.Extension
	} else {
		$Temp = Get-Item $JobOutput
		$OutputFilename = $Temp.DirectoryName + [IO.Path]::DirectorySeparatorChar + $Temp.Basename + '_FORMATTED' + $Temp.Extension
	}
	# Default lines to go to the header unless we can determine otherwise
	$ParsedData = [ordered]@{'HEADER' = @()}
	$Section = 'HEADER'
	ForEach ($Line in $JobLog) {
		# Skip blank lines since we'll add them ourselves during the output portion.
		if ($Line.Length -eq 0) { continue }
		$AddLine = $false
		$LineServerName = 'UNKNOWN'
		if ($Line -match $ServerNameExtractionRegex) {
			# Remove the first match, which is the whole line that was matched
			$Matches.Remove(0)
			# Remove blank entries
			$LineServerName = ($Matches.Values.Where({ $_ -ne "" }))[0].ToUpper()
		}
		if ($SystemName) {
			if ($LineServerName -ne 'UNKNOWN') {
				$TempSystemName = $SystemName.ToUpper()
				if ($LineServerName -match $TempSystemName) {
					$AddLine = $true
				}
			} else {
				# No matched server name, probably header stuff
				$AddLine = $true
			}
		} else {
			# Not filtering, add all lines
			$AddLine = $true
		}
		# This section creates a dictionary of arrays with the dictionary keys being the section
		# header and the array being the section line contents (including header).
		# Example below:
		# Key: TASK [role-name : Task Name] ***************************************************
		# Array Contents:
		#		TASK [role-name : Task Name] ***************************************************
		#		ok: [SERVER1] => {"backup": "", "changed": false, "msg": ""}
		#		ok: [SERVER2] => {"backup": "", "changed": false, "msg": ""}
		#		ok: [SERVER3] => {"backup": "", "changed": false, "msg": ""}		
		if ($AddLine) {
			if (
				($Line -match 'PLAY \[.+\] \*\*\*+') -or
				($Line -match 'TASK \[.+\] \*\*\*+') -or
				($Line -match 'PLAY RECAP \*\*\*+')
			) {
				# If this is a header line add a new dictionary key and seed the value array
				# with the header line as well.
				$Section = $Line
				if (-not $ParsedData.Contains($Section)) {
					$ParsedData.Add($Section, @($Line))
				}
				continue
			}
			if ($Line.substring(0, 8) -eq 'included') {
				# Move the includeds to the header since they're ALWAYS out of place
				$ParsedData['HEADER'] += $Line
			} elseif ($Line.substring(0, 11) -ne '...ignoring') {
				# All other lines get added to the most recent section found
				$ParsedData[$Section] += $Line
			}
		}
	}

	$FinalContent = @()

	ForEach ($Section in $ParsedData.Keys) {
		if ($Section -eq 'HEADER') {
			# Skip sorting and other fancy stuff for the special header content
			$Lines = $ParsedData[$Section]
		} else {
			# Print the Section header
			$FinalContent += $ParsedData[$Section][0]
			# Remove the section header from the array
			$Lines = $ParsedData[$Section] | Select-Object -Skip 1
			if ($NoSort -eq $false) {
				# Sort all the remaining lines by server name for consistency
				# using our fancy Server Name Extraction Regex from above
				$Lines = $Lines | Sort-Object @{Expression={
					if ($_ -match $ServerNameExtractionRegex) {
						$Matches.Remove(0)
						($Matches.Values.Where({ $_ -ne "" }))[0].ToUpper()
					}
				}; Ascending=$true}
			}
		}
		# Print all server entries sorted
		$FinalContent += $Lines
		# Blank line before the next section
		$FinalContent += ''
	}
	# Write the file
	$($FinalContent -Join "`n") | Out-File $OutputFilename
}