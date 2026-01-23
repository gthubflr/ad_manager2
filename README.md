# ad_manager2

A Flutter-based Android app to manage a **Samba 4 Active Directory / LDAP** environment directly from your phone.

## 📱 Overview

`ad_manager2` is a Android application that allows basic administration of a Samba 4 Active Directory.  
It was built primarily for **homelab and emergency use cases**, when quick access to AD management is needed without a desktop.

I originally have **no professional Android development background** and consider myself more of a sysadmin.  
Years ago, I set up a Samba 4 AD in my homelab and relied on an old Android app from the Play Store for simple tasks like:

- resetting my user password  
- re-enabling my account after locking myself out  
- assigning users to groups  

Unfortunately, that app stopped working on my new phone.  
I also couldn’t find a replacement that supported **self-signed CA certificates**, which is the case in my homelab setup.

So, after wanting to try *vibe coding* for a while, I decided to build my own app using AI assistants like **Claude** and **Gemini**.

## ✨ Features

The app currently supports the following modules:

- ✅ tested under Android 15
- ✅ Enable / disable users  
- 🔑 Set user passwords  
- 👥 View groups and group details  
- 👤 View users and user details  
- 💻 View computers and computer details  
- 🔗 Assign / remove users or groups to/from other groups  
  *(available in the group section)*

## 🚀 Getting Started

You can either:

- 📦 **Download the APK**, or  
- 🛠 **Clone the repository** and build the app yourself using Flutter

Choose whatever fits your workflow best.

## ☕ Support

If this app helps you and you’d like to support my work,  
you can **donate a coffee via PayPal** using the link provided in the repository.

## ❤️ Final Words

This app was created mainly for my own needs, but maybe it helps someone else out there too.  
Feel free to try it, improve it, or fork it.
