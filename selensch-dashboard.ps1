Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- HAUPTFENSTER ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "selensch-dashboard (Admin Reporting)"
$form.Size = New-Object System.Drawing.Size(1000, 700)
$form.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$form.StartPosition = "CenterScreen"

# --- TOP NAVIGATION PANEL ---
$navPanel = New-Object System.Windows.Forms.Panel
$navPanel.Size = New-Object System.Drawing.Size(1000, 60)
$navPanel.Dock = "Top"
$navPanel.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
$form.Controls.Add($navPanel)

# --- CONTENT PANEL ---
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Dock = "Fill"
$form.Controls.Add($contentPanel)

# --- LOG / STATUS FENSTER (Unten) ---
# Wichtig, damit man sieht, was das Hintergrund-Skript macht
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Dock = "Bottom"
$logBox.Height = 150
$logBox.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15)
$logBox.ForeColor = "LightGray"
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logBox.ReadOnly = $true
$logBox.Text = "Dashboard bereit. Warte auf Befehle..."
$contentPanel.Controls.Add($logBox)


# --- TIMER FÜR HINTERGRUNDJOBS ---
# Dieser Timer prüft jede Sekunde, ob ein Job läuft, damit die GUI nicht einfriert.
$jobTimer = New-Object System.Windows.Forms.Timer
$jobTimer.Interval = 1000 # 1 Sekunde
$jobTimer.Add_Tick({
    $job = Get-Job -Name "LongRunningTask" -ErrorAction SilentlyContinue
    
    if ($job) {
        # Job läuft noch oder ist fertig -> Output abholen
        $results = Receive-Job -Job $job -Keep
        if ($results) {
            # Nur neuen Text hinzufügen (simuliert)
            # In einer echten App würde man hier intelligenter parsen
            # Hier scrollen wir einfach nach unten
            $logBox.AppendText("`n> Arbeitet...") 
            $logBox.ScrollToCaret()
        }

        if ($job.State -eq 'Completed') {
            $jobTimer.Stop()
            $logBox.AppendText("`n--- ABGESCHLOSSEN ---`n")
            
            # Ergebnis holen und Job aufräumen
            $finalData = Receive-Job -Job $job
            Remove-Job -Job $job
            
            [System.Windows.Forms.MessageBox]::Show("Das Skript ist fertig!", "Erfolg")
        }
        elseif ($job.State -eq 'Failed') {
            $jobTimer.Stop()
            $logBox.AppendText("`n!!! FEHLER !!!`n")
            Remove-Job -Job $job
        }
    }
})


# --- FUNKTION: INHALT ZEICHNEN ---
function Show-CategoryContent {
    param($CategoryName)
    
    # Alten Inhalt löschen (außer der Logbox, die ist gedockt unten)
    # Wir entfernen nur Controls, die NICHT die Logbox sind
    $controlsToRemove = @()
    foreach($ctrl in $contentPanel.Controls) {
        if ($ctrl -ne $logBox) { $controlsToRemove += $ctrl }
    }
    foreach($c in $controlsToRemove) { $contentPanel.Controls.Remove($c) }
    
    # Überschrift
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "$CategoryName Reporting"
    $lbl.ForeColor = "DodgerBlue"
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $lbl.Location = New-Object System.Drawing.Point(30, 20)
    $lbl.AutoSize = $true
    $contentPanel.Controls.Add($lbl)

    # Aktions-Gruppe
    $actionGroup = New-Object System.Windows.Forms.GroupBox
    $actionGroup.Text = "Actions"
    $actionGroup.ForeColor = "White"
    $actionGroup.Location = New-Object System.Drawing.Point(30, 70)
    $actionGroup.Size = New-Object System.Drawing.Size(300, 300)
    $contentPanel.Controls.Add($actionGroup)

    # --- SPEZIALFALL: VMWARE ---
    if ($CategoryName -eq "VMware") {
        
        $btnFileServer = New-Object System.Windows.Forms.Button
        $btnFileServer.Text = "New FileServer (2h Script)"
        $btnFileServer.Location = New-Object System.Drawing.Point(20, 40)
        $btnFileServer.Size = New-Object System.Drawing.Size(260, 50)
        $btnFileServer.FlatStyle = "Flat"
        $btnFileServer.BackColor = "DarkGreen"
        $btnFileServer.ForeColor = "White"
        
        $btnFileServer.Add_Click({
            $logBox.Text = "Starte 'New FileServer' Prozess... GUI bleibt aktiv."
            
            # --- HIER STARTET DER BACKGROUND JOB ---
            # Das Skript läuft in einem eigenen Prozess. 
            # Deine GUI friert NICHT ein.
            
            Start-Job -Name "LongRunningTask" -ScriptBlock {
                # --- DEIN ECHTES SKRIPT KOMMT HIER REIN ---
                # Zum Testen simulieren wir Arbeit:
                
                Write-Output "Initialisiere..."
                Start-Sleep -Seconds 2
                Write-Output "Erstelle VM..."
                Start-Sleep -Seconds 3
                Write-Output "Installiere Rollen..."
                Start-Sleep -Seconds 3
                Write-Output "Konfiguration läuft..."
                # ... dein 2h Skript ...
                
                return "Fertig"
            } | Out-Null
            
            # Timer starten, der den Job überwacht
            $jobTimer.Start()
        })
        
        $actionGroup.Controls.Add($btnFileServer)

    } else {
        # Standard Button für andere Kategorien
        $btnReport = New-Object System.Windows.Forms.Button
        $btnReport.Text = "Standard CSV Report"
        $btnReport.Location = New-Object System.Drawing.Point(20, 40)
        $btnReport.Size = New-Object System.Drawing.Size(260, 40)
        $btnReport.FlatStyle = "Flat"
        $btnReport.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $btnReport.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Standard Report für $CategoryName") })
        $actionGroup.Controls.Add($btnReport)
    }
}

# --- TOP BUTTONS ERSTELLEN (RECHTSBÜNDIG) ---
$tabs = @("Exchange", "VMware", "Hyper-V", "Azure", "Windows Server")

# Berechnung für Rechtsbündigkeit
$buttonWidth = 120
$gap = 10
$totalWidthNeeded = ($tabs.Count * ($buttonWidth + $gap))
# Startposition = PanelBreite - Benötigter Platz - Kleiner Rand
$xPos = $navPanel.Width - $totalWidthNeeded - 20 

foreach ($tab in $tabs) {
    $btnTab = New-Object System.Windows.Forms.Button
    $btnTab.Text = $tab
    $btnTab.Size = New-Object System.Drawing.Size($buttonWidth, 40)
    $btnTab.Location = New-Object System.Drawing.Point($xPos, 10)
    $btnTab.FlatStyle = "Flat"
    $btnTab.FlatAppearance.BorderSize = 0
    $btnTab.ForeColor = "White"
    $btnTab.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnTab.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    # Wichtig: Anchor Right sorgt dafür, dass sie beim Vergrößern rechts bleiben
    $btnTab.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right

    $btnTab.Add_Click({ 
        Show-CategoryContent -CategoryName $this.Text 
        foreach($c in $navPanel.Controls) { $c.BackColor = [System.Drawing.Color]::Transparent }
        $this.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    })
    
    $navPanel.Controls.Add($btnTab)
    $xPos += ($buttonWidth + $gap)
}

# Initialen Inhalt anzeigen
Show-CategoryContent -CategoryName "Exchange"

# --- START ---
$form.ShowDialog() | Out-Null