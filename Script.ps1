  [cmdletbinding()]
  Param()
  $i= 0
  $encodingMail = [System.Text.Encoding]::UTF8
  $NbMailMax = 10 # nb max of mail
  $NbDate = -30 # to get all posts of the month
  $From = "your@mail.com"
  $to = "theonewho@received.it"
  $Smtp = "the SMTP server "
  $rss = Invoke-RestMethod https://www.cert.ssi.gouv.fr/feed/  |
  Select Title,link,@{Name="Published";Expression = {$_.pubdate -as [datetime]}} | where-object {
  $_.title -match "Netlogon" -or
  $_.title -match "Windows" -or
  $_.title -match "Passbolt" -or
  $_.title -match "Active Directory" -or
  $_.title -match "Fortinet" -or
  $_.title -match "cisco" -or
  $_.title -match "Oracle" -or
  $_.title -match "Sonicwall" -and
  $_.published -ge $(get-date).AddDays($NbDate)
  }
  do{
      $title = $rss | select title | select-object -index $i # I select just one line, to send one email / line
      $body = $rss | select link , published | select-object -index $i

      $title = $title -replace '@{title=',' ' # I replace the useless things
      $title = $title -replace '}',' '
      $body = $body -replace '@{link=',' '
      $body = $body -replace '; Published=','  '
      $body = $body -replace '}',' '
      echo $title
      echo $body
      $title= [system.String]::Join(" ", $title) # Change the object by string
      $body= [system.String]::Join(" ", $body)
      if ($title -ne "")  # If $title is null e don't send the E-mail
      {
      send-mailmessage -From $From -To $To -Subject $title -Bodyashtml $body -Smtpserver $Smtp -Encoding $encodingMail
      $i++
      }
  }until($title -eq "") # We do the until the last post
