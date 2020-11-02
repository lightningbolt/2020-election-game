# 2020 Election Game

## Development dependencies
* Developed with Ruby 2.6.3p62 on Mac
* roo 2.8.3 gem, to install run: 
        $ sudo gem install roo -v 2.8.3

## Directions
1. Ensure **election-game.rb**, **candidates.yml**, and **districts.yml** are in the same directory and there is a **xlsx** directory.
2. **candidates.yml** has list of strings that it will attempt to match for each candidate after removing punctuation, capitalization, and whitespace.
3. Update **districts.yml** with the winner for each district (replace `:tbd` with `:biden` or `:trump`).
4. Place submitted XLSX files in the **xlsx** directory in the format **[contestant name]-[rest of filename].xlsx**.
5. The script assumes that the layout of the XLSX spreadsheets are exactly the same as the original and only the "Decision" column has been filled out.
6. Included are 3 test XLSX files for testing.
7. To test with randomly generated election results (this ignores declared winners in **districts.yml**), run:
        $ ./election-game.rb --test
8. Run for real:
        $ ./election-game.rb
