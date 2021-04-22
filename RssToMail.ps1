[cmdletbinding()]
Param()
$i= 0
$path = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition) # Pour avoir le chemin du scripte, il fonctionnera donc n'importe ou.
$fichier1 = $path+"\date.txt"
$test1 = Test-Path $fichier1
if ($test1 -ne "True") { # Si le fichier n'existe pas je le crée avec une vielle date
New-Item -ItemType file -Path $fichier1 -Force 
Add-Content -Path $fichier1 -Value "01/01/2000 12:12:12"
}
$listtitle = @()#déclaration des "collections"
$listbody = @()
$listdate = @()
$encodingMail = [System.Text.Encoding]::UTF8 # Pour les accents 
$NbMailMax = 10 # Nombre maximum de mail par passe 
$NbJours = -9# si tu lances le script toutes les semaines tu mets 7 pour avoir les infos des 7 derniers jours 
$From = "exemple@mail.com"
$to = "exemple@mail.com"

$Smtp = "the SMTP server"
$test1 = Test-Path $fichier1 # Si le fichier n'existe pas je le créer
if ($test1 -ne "True") { New-Item -ItemType file -Path $fichier1 -Force }

$rss = Invoke-RestMethod https://www.cert.ssi.gouv.fr/feed/  |
Select Title,link,@{Name="Published";Expression = {$_.pubdate -as [datetime]}} | where-object {
$_.title -match "Netlogon" -or # si un de ces mots est présent dans le titre il envoie le mail
$_.title -match "Windows" -or
$_.title -match "Passbolt" -or
$_.title -match "Active Directory" -or
$_.title -match "Fortinet" -or
$_.title -match "cisco" -or
$_.title -match "Oracle" -or
$_.title -match "Sonicwall" -and

$_.published -ge $(get-date).AddDays($NbJours)# Pour avoir les infos de la semaine. il est possble de mettre -1 pour avoir que la journée
}
do{
    $title = $rss | select title | select-object -index $i # je sélectionne juste une ligne
    $body = $rss | select link , published | select-object -index $i
    $title = $title -replace '@{title=',' ' # Je remplace les balises inutiles
    $title = $title -replace '}',' '
    $body = $body -replace '@{link=',' '
    $body = $body -replace '; Published=',' '
    $body = $body -replace '}',' '
    $title= [system.String]::Join(" ", $title) # Changer l'obj en str pour le mail
    $body= [system.String]::Join(" ", $body) 
    if ($title -ne "") # Si le titre est pas vide on envoie le mail
    {
    $date = $body.Substring($body.Length-20) #je récupère la date en string
    $listtitle += $title
    $listbody += $body
    $listdate += $date
    $i++
    }

}until($title -eq "") # On continue jusqu'à ce qu'il n'y ai plus de flux RSS
$i = $i - 1
do{
    $lastdate = Get-Content $fichier1
    $lastdate = (Get-Date $lastdate) #vue que c'est un fichier texte il y a un retour a la ligne, donc dans startdate[0] il y a la date, startdate[1] est vide 
    $enddate   = (Get-Date $listdate[$i])
    $diff = $enddate -  $lastdate 
    if($diff.TotalSeconds -gt 0){
        echo "envoie, remplacement de la date"
        Clear-Content $fichier1
        Add-Content -Path $fichier1 -Value $enddate
        #send-mailmessage -From $From -To $To -Subject $title -Bodyashtml $body -Smtpserver $Smtp -Encoding $encodingMail
        send-mailmessage -From $From -To $To -Subject $listtitle[$i] -Bodyashtml $listbody[$i] -Smtpserver $Smtp -Encoding $encodingMail
    }else{
        echo "pas envoie"
    }
    echo $i
    $i = $i - 1 
}until($i -eq -1)