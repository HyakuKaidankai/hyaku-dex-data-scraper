# Hyaku Dex Data Scraper and Parser

This PowerShell script aims to scrape some data from the different Pokemon Tabletop United pokedexes that are available (See `dexes/README.md` for more information), in order to generate a unified JSON file. 

This has been done for the [Hyaku Dex](https://github.com/HyakuKaidankai/hyaku-dex) project, so the idea was to only parse the information that could not be obtained from other sources (The character sheets on Google Sheets, for example). As of writing, said information includes:
- Pokemon evolutions 
- Pokemon moves

Normally, we could use PokeAPI to obtain this information, but move lists on PTU have some differences with the official data: different evolution levels and methods, homebrew moves and other balance changes. Still, some cross checking with PokeAPI could be beneficial in the future, in order to check for move lists that have been changed across generations.

## Requirements

Because of ternary operator usage, this script requires PowerShell 7.0 or higher.
If needed, changing them to good old `if` statements should be trivial.

## Usage

Just run the `process_DexInfo.ps1` script, and it will generate a `dex_info.json` and a `dex_info_compressed.json` file in the root of the project. Both files have the same content, the compressed file is noticeably smaller than the other one.

A successful run of the script should generate the following output:
```
- Processing file .\dexes\Dex_Data.txt
 > Found pokemon data
- Processing file .\dexes\Dex_Hisui.txt
 > Found pokemon data
- Processing file .\dexes\Dex_Gen9.txt
 > Found pokemon data
Move conversion started
Move conversion finished
Evolution conversion started
Evolution conversion finished
- Generating dex files
```

## Debugging

In addition to using native Powershell debugging capabilities in VS Code, I have added a `Write-Log` function that will write the given string to a log file. Its disabled by default, as it makes the script run magnitudes slower, but can be enabled by setting `log_enabled` to `true` in the `config.json` file.