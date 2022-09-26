# Deadman Account

> An account that locks up funds and releases them if owner of funds disappears.

Owner can set up an account and deposit funds greater than the set minimum deposit. The owner declares a backup account for the funds. The owner has to respond to the contract pings for the set time period. If the owner doesn't respond, the funds will be sent to the backup account. The backup accounts can be updated any time.

[Contract Source](src/deadman.sol)
