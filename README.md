

<div align="center">
<h1 style="font-size: 3rem; margin-bottom: 1.5rem;">
CLIP PASTE
</h1>
</div>

Hi! Clip Paste is a small utility app for Finder on macOS.

It looks like this:

<img width="484" height="395" alt="Clip Paste settings panel" src="https://github.com/user-attachments/assets/46e9f36c-45e4-43de-a048-be2eb6913ad4" />

Its only user interface is the settings panel shown above.  
Here is what the app was made for:

- **Current behavior:** When you try to paste something that is not a file or a folder in Finder, nothing happens.
- **With Clip Paste:** When the app detects text or an image in the clipboard and you try to paste directly into Finder, it automatically creates either:
  - an image file, or
  - a text file,
  in the folder where you attempted to paste.

## Customization

- Enable or disable image and text file creation (see images below)
- Customize the filename templates
- Choose a default save location used when the shortcut is triggered outside Finder
- Choose which keyboard shortcut activates the action

<img width="479" height="392" alt="Image settings" src="https://github.com/user-attachments/assets/c8687ddd-7f46-4229-a64a-7436b5e08b9e" />
<img width="480" height="390" alt="Text settings" src="https://github.com/user-attachments/assets/8e4bcb30-0adf-423e-944e-a5186c47eea3" />

## Installation Instructions

- **Required:** macOS 14.6 or newer
- Go to the latest release here: https://github.com/EllandeVED/Clip-Paste/releases/latest
- Download the `.zip` file from the Releases page
- When opening the app for the first time, you will see the following message  
  (this happens because the app is not signed with a registered Developer ID):

<img width="266" height="239" alt="Security warning" src="https://github.com/user-attachments/assets/70f15712-db61-4e88-b80d-cb4d459e64fe" />

- Go to **System Settings → Privacy & Security** and click **“Open Anyway”**

<img width="722" height="630" alt="Privacy and Security panel" src="https://github.com/user-attachments/assets/45f84291-ed1a-44c2-b0ab-3c9fbfa83f30" />

## Updates

- Follow the in-app instructions
- Make sure the app is located in the **Applications** folder for automatic updates to work reliably

## Currently Working On

- Custom locations for the default save folder
- Support for more image formats
- Support for more text formats (including formatting)
- A **Hide Dock Icon** option
- A **Check for Updates** enable/disable option
- An optional menu bar icon


