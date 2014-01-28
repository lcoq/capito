# Capito Changelog

### Unreleased

* Add Rails 4 compatibility

### Capito 0.0.4 (January 18, 2014)

* `Translatable#destroy_translation`

### Capito 0.0.3 (January 6, 2014)

* Update `activerecord` and `activemodel` dependencies to accepts `~> 3.2.9`

### Capito 0.0.2 (December 27, 2013)

* Translatable accepts `translations` attributes
* Errors serialization (`Translatable#errors_hash`)
* Translations autobuild before validations (`translates(:autobuild)` option)
* Translations associated validations
* Translation class shortcut for translated model (eg: `Product::Translation#product` )
* Translations attributes are accessible
* Dynamic finders (find_by, find_or_initialize_by,..)

### Capito 0.0.1 (December 2, 2013)

* Initial release
