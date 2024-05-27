# Load necessary assemblies
Add-Type -AssemblyName PresentationFramework

# Create the main window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
        Title="Windows Toolbox" Height="400" Width="600">
    <Grid>
        <Button x:Name="btnSystemInfo" Content="System Information" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <Button x:Name="btnDiskManagement" Content="Disk Management" HorizontalAlignment="Left" Margin="10,50,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <Button x:Name="btnNetworkDiagnostics" Content="Network Diagnostics" HorizontalAlignment="Left" Margin="10,90,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <Button x:Name="btnUserManagement" Content="User Management" HorizontalAlignment="Left" Margin="10,130,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <Button x:Name="btnProcessManagement" Content="Process Management" HorizontalAlignment="Left" Margin="10,170,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <Button x:Name="btnClearBloatware" Content="Clear Bloatware" HorizontalAlignment="Left" Margin="10,210,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <Button x:Name="btnExit" Content="Exit" HorizontalAlignment="Left" Margin="10,250,0,0" VerticalAlignment="Top" Width="150" Height="30"/>
        <TextBox x:Name="txtOutput" HorizontalAlignment="Left" Height="320" Margin="180,10,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="400" IsReadOnly="True"/>
    </Grid>
</Window>
"@

# Parse the XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Define button click event handlers
$Window.FindName('btnSystemInfo').Add_Click({
    $output = Get-ComputerInfo | Out-String
    $Window.FindName('txtOutput').Text = $output
})

$Window.FindName('btnDiskManagement').Add_Click({
    $output = Get-PhysicalDisk | Format-Table -AutoSize | Out-String
    $output += "`n" + (Get-Volume | Format-Table -AutoSize | Out-String)
    $Window.FindName('txtOutput').Text = $output
})

$Window.FindName('btnNetworkDiagnostics').Add_Click({
    $output = "IP Configuration:`n" + (ipconfig /all | Out-String)
    $output += "`nTest Network Connection:`n" + (Test-Connection google.com -Count 4 | Out-String)
    $output += "`nNetwork Adapters:`n" + (Get-NetAdapter | Format-Table -AutoSize | Out-String)
    $Window.FindName('txtOutput').Text = $output
})

$Window.FindName('btnUserManagement').Add_Click({
    $output = "User Management:`n" + (Get-LocalUser | Format-Table -AutoSize | Out-String)
    $Window.FindName('txtOutput').Text = $output
})

$Window.FindName('btnProcessManagement').Add_Click({
    $output = "Running Processes:`n" + (Get-Process | Format-Table -AutoSize | Out-String)
    $Window.FindName('txtOutput').Text = $output
})

$Window.FindName('btnClearBloatware').Add_Click({
    # Check for administrative privileges
    If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        # If not running as administrator, re-run the script with elevated privileges
        $arguments = "& '" + $myinvocation.mycommand.definition + "'"
        Start-Process powershell -Verb runAs -ArgumentList $arguments
        Exit
    }

    # Your existing script starts here
    $apps = @(
        "Microsoft.BingWeather",
        "Microsoft.Getstarted",
        "Microsoft.Messaging",
        "Microsoft.Microsoft3DViewer",
        "Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.MixedReality.Portal",
        "Microsoft.Office.OneNote",
        "Microsoft.OneConnect",
        "Microsoft.People",
        "Microsoft.Print3D",
        "Microsoft.SkypeApp",
        "Microsoft.StorePurchaseApp",
        "Microsoft.Wallet",
        "Microsoft.Windows.Photos",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo"
    )

    $output = ""
    foreach ($app in $apps) {
        $output += "Removing $app`n"
        try {
            Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        }
        catch {
            $output += "Failed to remove $app ${_}`n"
        }
    }
    $output += "Done`n"
    $Window.FindName('txtOutput').Text = $output
})

$Window.FindName('btnExit').Add_Click({
    $Window.Close()
})

# Show the window
$Window.ShowDialog() | Out-Null
