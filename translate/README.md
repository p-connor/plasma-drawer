## Welcome

Welcome to the translations readme! If you wish to contribute and add translations for your language, follow the steps below. If the following steps are confusing or if have any questions throughout the process, feel free to reach out to me for support by [adding an issue](https://github.com/P-Connor/plasma-drawer/issues/new/choose) on the github repository. I really appreciate your efforts in making Plasma Drawer more accessible to all!

## New Translations

To add a new translation:

1. Find your language's 2-letter [ISO 639-1 code](https://en.wikipedia.org/wiki/ISO_639-1_codes) (for example: English is '`en`'). 
    
    Note: If the translations you are adding are specific to a specific country or territory, append the 2-letter [ISO 3166-1 country code](https://en.wikipedia.org/wiki/ISO_3166-1#Current_codes) to the language code with an underscore (for example, American English would be '`en_US`').

    You can use the `locale` command to see the current language code your system is using, and `locale -a` to see all currently available locales on your system.

2. Copy [`template.pot`](template.pot) to a new file and name it `ll.po`, where `ll` is the locale code you found earlier (for example, '`en_US.po`').
3. Edit the file in a text editor and fill out the following fields at the top of the file


        # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
        ...
        "PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
        "Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
        "Language-Team: LANGUAGE <LL@li.org>\n"
        "Language: LL\n"
        ...

4. Then begin translating. For each line `msgid "English Phrase"`, fill in the `msgstr` quotes below with the translated phrase. 
    
    For example, if you were translating from English to Spanish, one phrase would look like this:
    
        msgid "Applications:"
        msgstr "Aplicaciones:"
    
5. Once all phrases are translated, save the file and attach it to a [new github issue](https://github.com/P-Connor/plasma-drawer/issues/new/choose). I will review it and add the translation in the next widget update.

    Alternatively, if you're a bit more tech-savvy, you can run merge.sh, build.sh, and plasmoidlocaletest.sh in that order to build the translation and test it. Then [submit a pull request](https://github.com/P-Connor/plasma-drawer/compare) in the development branch.

## Scripts

The following scripts were retrieved from [Zren's Widget Library Repository](https://github.com/Zren/plasma-applet-lib/tree/master/package/translate)

* `sh ./merge.sh` will parse the `i18n()` calls in the `*.qml` files and write it to the `template.pot` file. Then it will merge any changes into the `*.po` language files.
* `sh ./build.sh` will convert the `*.po` files to it's binary `*.mo` version and move it to `contents/locale/...` which will bundle the translations in the `*.plasmoid` without needing the user to manually install them.
* `sh ./plasmoidlocaletest.sh` will run `./build` then `plasmoidviewer` (part of `plasma-sdk`).

## Learn More

* https://develop.kde.org/docs/plasma/widget/translations-i18n/#ki18n

## Translation Statuses
|  Locale  |  Lines  | % Done|
|----------|---------|-------|
| Template |      43 |       |
| ru       |   43/43 |  100% |
| uk       |   43/43 |  100% |
