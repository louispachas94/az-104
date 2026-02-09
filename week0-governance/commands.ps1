# ---------------------------
# WEEK 0: Foundation + Governance Guardrails (AZ-104)
# ---------------------------

# Show PowerShell version (sanity check that pwsh is working)
$PSVersionTable  # Shows your current PowerShell version info

# Update Az modules (optional but recommended so you're not learning on stale cmdlets)
# Update-Module -Name Az -Scope CurrentUser -Force  # Updates Az module for the current user (may take a bit)

# Install required modules if missing (Az is the base; Az.Billing is for budgets)
# Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force  # Installs Az if you don't have it
# Install-Module -Name Az.Billing -Scope CurrentUser -Repository PSGallery -Force  # Installs budget cmdlets

# Sign in to Azure (device auth works well in terminals)
Connect-AzAccount  # Authenticates your account for Azure PowerShell sessions

# Show current context (tenant + subscription you are about to run commands against)
Get-AzContext  # Verifies you're pointed at the correct tenant/subscription

# List subscriptions you can access (useful if you have more than one)
Get-AzSubscription | Select-Object Name, Id, TenantId  # Displays available subscriptions

# (Optional) Set the correct subscription explicitly (prevents "oops wrong sub")
# Set-AzContext -Subscription "<YOUR-SUBSCRIPTION-ID>"  # Forces the session to target the right subscription

# ---------------------------
# Create the lab Resource Group
# ---------------------------

$rgName    = "rseahawks-rg"  # Resource group name for all labs
$location  = "westus2"       # Pick a region and stick to it (change if you want)

# Create the resource group (idempotent-ish: if it exists, you’ll just read it later)
New-AzResourceGroup -Name $rgName -Location $location  # Creates the RG in your chosen region

# ---------------------------
# Apply tags (governance hygiene)
# ---------------------------

# Tags help organize and report cost across resources (use consistent keys/values)
$tags = @{  # Tag dictionary
  "project" = "az104"        # What this RG is for
  "env"     = "lab"          # Environment type
  "delete"  = "after-exam"   # Reminder to clean up later
}  # End tag dictionary

# Apply tags to the RG
Set-AzResourceGroup -Name $rgName -Tag $tags  # Writes tags to the RG

# Verify tags
(Get-AzResourceGroup -Name $rgName).Tags  # Prints the tag set

# ---------------------------
# Add a deletion lock (prevents accidental deletion)
# ---------------------------

$lockName = "lock-rg-az104-cannotdelete"  # Lock name

# Create a CanNotDelete lock at the RG scope
New-AzResourceLock -LockName $lockName -LockLevel CanNotDelete -ResourceGroupName $rgName  # Adds deletion protection

# Verify locks on the RG
Get-AzResourceLock -ResourceGroupName $rgName | Select-Object Name, LockLevel, Notes  # Confirms lock exists

# ---------------------------
# Budget guardrail (cost control)
# ---------------------------

# Create a monthly budget with an email alert when hitting a threshold
# NOTE: Budgets are for tracking/alerting, not a hard stop. (You still must delete resources.) 

$budgetName  = "az104-lab-budget"         # Budget name
$budgetAmt   = 25                        # Monthly budget amount (keep low)
$startDate   = (Get-Date -Day 1).Date    # First day of current month
$endDate     = (Get-Date).AddYears(1).Date  # One year out so it stays active
$notifyKey   = "80Percent"               # Notification key name
$threshold   = 80                        # Alert at 80%
$email       = @("REPLACE_ME@example.com")  # Replace with your email

# Create the budget (subscription-level by default; add -ResourceGroupName $rgName if you want RG-level)
New-AzConsumptionBudget `
  -Name $budgetName `                    # Budget name
  -Amount $budgetAmt `                   # Budget amount
  -Category Cost `                       # Track cost
  -TimeGrain Monthly `                   # Monthly reset
  -StartDate $startDate `                # Start date
  -EndDate $endDate `                    # End date
  -NotificationKey $notifyKey `          # Notification label
  -NotificationThreshold $threshold `    # % threshold
  -ContactEmail $email                   # Alert email(s)

# Verify the budget exists
Get-AzConsumptionBudget | Select-Object Name, Amount, TimeGrain  # Shows budgets found in scope