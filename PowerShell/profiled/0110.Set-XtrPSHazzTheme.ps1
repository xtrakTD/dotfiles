Function Set-XtrPSHazzTheme
{
    [CmdletBinding()]
    param()
    
    [string[]]$themes=(pshazz list).Split([System.Environment]::NewLine)
    if(($themes | ?{ $_.Trim() -eq 'xtr' }) -eq $null)
    {
        New-Item -Path $env:USERPROFILE\pshazz -Name xtr.json -ItemType File -Value '
        
            {
    	      "comment": "Dmitry Minin 2018",
              "plugins": [ "git", "ssh", "z", "aliases", "xtr" ],
              "prompt": [
      	        [ "White", "", "$prompt_brakTop"],
    	        [ "White", "DarkRed", " $time " ],
                [ "DarkRed", "Blue", "$rightarrow" ],
                [ "White", "Blue", " $path " ],
                [ "Blue", "", "$no_git" ],
                [ "Blue", "Green", "$yes_git" ],
                [ "DarkBlue", "Green", " $git_lbracket" ],
                [ "DarkBlue", "Green", "$git_branch" ],
                [ "DarkGreen", "Green", " $git_local_state" ],
                [ "DarkGreen", "Green", " $git_remote_state" ],
                [ "DarkBlue", "Green", "$git_rbracket " ],
                [ "Green", "", "$yes_git" ],
                [ "White", "", " `n$prompt_brakBottom" ],
                [ "Yellow", "DarkRed", "$admin_seclineprompt" ],
                [ "DarkRed", "", "$admin_rightarrow" ],
                [ "Yellow", "Blue", "$nonadmin_seclineprompt" ],
                [ "Blue", "", "$nonadmin_rightarrow" ]
              ],
              "git": {
                "prompt_lbracket": "[",
                "prompt_rbracket": "]",
                "prompt_unstaged": "*",
                "prompt_staged": "+",
    	        "prompt_stash": "$",
                "prompt_untracked": "%",
                "prompt_remote_push": ">",
                "prompt_remote_pull": "<",
                "prompt_remote_same": "="
              },
              "hg": {
      	        "prompt_dirty": "*"
    	        }
            }
                        '
    }
    pshazz init xtr
}