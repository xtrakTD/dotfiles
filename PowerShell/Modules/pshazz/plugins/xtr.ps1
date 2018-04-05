function isAdmin {
  $tempuser = [Security.Principal.WindowsIdentity]::GetCurrent();
  $isAdmin = (New-Object Security.Principal.WindowsPrincipal $tempuser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
  return $isAdmin
}

function pshazz:xtr:init {
  
  $xtr = $global:pshazz.theme.xtr

  $lambda = $xtr.prompt_lambda
  $forwardArrow = $xtr.prompt_forwardArrow
  $alphaCap = $xtr.prompt_alphaCap
  $alphaSmall = $xtr.prompt_alphaSmall
  $deltaCap = $xtr.prompt_deltaCap
  $deltaSmall = $xtr.prompt_deltaSmall
  $muCap = $xtr.prompt_muCap
  $mSmall = $xtr.prompt_mSmall
  $iotaSmall = $xtr.prompt_iotaSmall
  $etaSmall = $xtr.prompt_etaSmall
  $signSmall = $xtr.prompt_signSmall
  $gear = $xtr.prompt_gear
  $bug = $xtr.prompt_bug
  $isAdmin = $xtr.isAdmin
  $seclinePrompt = $xtr.seclinePrompt
  $sumTop = $xtr.prompt_sumTop
  $sumBottom = $xtr.prompt_sumBottom
  $brakTop = $xtr.prompt_brakTop
  $brakBottom = $xtr.prompt_brakBottom


  if($isAdmin -eq $null) { $isAdmin = isAdmin }
  if(!$forwardArrow) { $forwardArrow = [char]::ConvertFromUtf32(8594) }
  if(!$alphaCap) { $alphaCap = [char]::ConvertFromUtf32(913) }
  if(!$alphaSmall) { $alphaSmall = [char]::ConvertFromUtf32(945) }
  if(!$lambda) { $lambda = [char]::ConvertFromUtf32(955) }
  if(!$deltaCap) { $deltaCap = [char]::ConvertFromUtf32(916) }
  if(!$deltaSmall) { $deltaSmall = [char]::ConvertFromUtf32(948) }
  if(!$muCap) { $muCap = [char]::ConvertFromUtf32(924) }
  if(!$mSmall) { $mSmall = [char]::ConvertFromUtf32(625) }
  if(!$iotaSmall) { $iotaSmall = [char]::ConvertFromUtf32(970) }
  if(!$etaSmall) { $etaSmall = [char]::ConvertFromUtf32(951) }
  if(!$signSmall) { $signSmall = [char]::ConvertFromUtf32(2947) }
  if(!$gear) { $gear = [char]0xe238 }
  if(!$bug) { $bug = [char]0xf188 }

  if(!$sumTop) { $sumTop = [char]0x23B2 }
  if(!$sumBottom) { $sumBottom = [char]0x23B3 }
  if(!$brakTop) { $brakTop = [char]0x2553 }
  if(!$brakBottom) { $brakBottom = [char]0x2559 }

  $seclinePrompt = ' '
  
  $global:pshazz.xtr = @{
    prompt_isadmin = $isAdmin
    prompt_lambda = $lambda
    prompt_forwardArrow = $forwardArrow
    prompt_alphaCap = $alphaCap
    prompt_alphaSmall = $alphaSmall
    prompt_deltaCap = $deltaCap
    prompt_deltaSmall = $deltaSmall
    prompt_muCap = $muCap
    prompt_mSmall = $mSmall
    prompt_iotaSmall = $iotaSmall
    prompt_etaSmall = $etaSmall
    prompt_signSmall = $signSmall
    prompt_gear = $gear
    prompt_bug = $bug
    seclinePrompt = $seclinePrompt
    prompt_sumTop = $sumTop
    prompt_sumBottom = $sumBottom
    prompt_brakTop = $brakTop
    prompt_brakBottom = $brakBottom
  }
}

function global:pshazz:xtr:prompt
{
  $vars = $global:pshazz.prompt_vars

  $vars.prompt_brakTop = $global:pshazz.xtr.prompt_brakTop
  $vars.prompt_brakBottom = $global:pshazz.xtr.prompt_brakBottom

  $vars.isAdmin = $global:pshazz.xtr.prompt_isadmin
  $vars.seclinePrompt += $global:pshazz.xtr.seclinePrompt
  $vars.prompt_forwardArrow = $global:pshazz.xtr.prompt_forwardArrow

  if ($global:pshazz.xtr.prompt_isadmin) {
      $vars.seclinePrompt += ("["+$global:pshazz.xtr.prompt_signSmall+" "+$global:pshazz.xtr.prompt_alphaSmall+$global:pshazz.xtr.prompt_deltaSmall+$global:pshazz.xtr.prompt_muCap+$global:pshazz.xtr.prompt_iotaSmall+$global:pshazz.xtr.prompt_etaSmall+" "+$global:pshazz.xtr.prompt_signSmall+"]")
  }
  else {
      $vars.seclinePrompt += " "
      if ($env:USERNAME -eq 'dmini') {
          $vars.seclinePrompt += ($global:pshazz.xtr.prompt_gear+" XTR "+$global:pshazz.xtr.prompt_gear)
      }
      else {
          $vars.seclinePrompt += ("["+$env:USERNAME+"] ")
      }
  }
  $vars.seclinePrompt += (" "+$vars.prompt_forwardArrow)
  
  if($vars.isAdmin) {
    $vars.admin_seclineprompt = $vars.seclinePrompt
    $vars.admin_rightarrow = $vars.rightarrow
    $vars.nonadmin_seclineprompt = $null
    $vars.nonadmin_rightarrow = $null
  }
  else {
    $vars.admin_seclineprompt = $null 
    $vars.admin_rightarrow = $null
    $vars.nonadmin_seclineprompt = $vars.seclinePrompt
    $vars.nonadmin_rightarrow = $vars.rightarrow
  }
}