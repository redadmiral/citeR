# citeR
citeR is a CLI tool to create Biblatex-Citations from URL, DOI or ISBN.

## Installation
Following instructions are tested under Ubuntu, but they should work under most modern Linux distributions.

1. `git clone` this repository or download at least `cite.R` and `credentials.txt`. Both files have to be in the same directory.

2. You proabably have to make cite.R executable:
```
chmod 755 cite.R
```
3. For more convenient usage I advise you to set an alias:
```
printf "#citeR\nalias cite='Rscript --vanilla /path/to/cite.R'"
```

### Amazon Credentials
Without the credentials for the amazon affiliate program it is not possible to call the API to cite by ISBN.

1. Follow these steps [provided by Amazon.](https://docs.aws.amazon.com/AWSECommerceService/latest/GSG/GettingStarted.html)
2. Insert your credentials in credentials.txt.

## Usage
When you've set the alias you can call citeR simply by
```
cite URL/DOI/ISBN
```
You can pipe the citation directly to your clipboard with
```
cite URL/DOI/ISBN | xclip -selection clipboard
```

## TODO
- [ ] Add R dependencies to Install section.
- [ ] Create installer.
- [ ] Implement exception handling.
- [ ] Implement just in time compilation.
- [ ] Improve citation by URL.
