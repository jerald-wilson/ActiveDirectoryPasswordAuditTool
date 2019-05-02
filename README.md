# ActiveDirectoryPasswordAuditTool
At a high level, this program pulls user information from Active Directory and cracks their passwords. The end goal is to find weak passwords and identify the user accounts, but NOT the passwords, that failed the audit. This tool will help harden a network's security by finding the weak passwords and identifying those users so they can be trained on how to create stronger passwords in the future.

This program uses "John the Ripper" and "NtdsAudit" for some core functionality. I will not be including those in the repository. The program requires them to be installed in the same directory, but the script currently just assumes that is already setup.


Jon the Ripper: https://github.com/magnumripper/JohnTheRipper
NtdsAudit: https://github.com/Dionach/NtdsAudit
