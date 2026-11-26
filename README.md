nedervetil-test-theme
=====================

A demonstration theme for [nedervetil](https://github.com/FOIMonkey/nedervetil-app), an
[Alaveteli](https://alaveteli.org) site. It gives the app a finished look and the data files
its features read, so a new install shows everything straight away. Everything in it is
invented: the topics, authorities and datasets are for demonstrating the software, not
for answering real requests.

The Docker quick start in nedervetil installs it and loads the matching sample data
(`bin/rails sample_data:load`), which uses the authorities named here.

## What is here

* `app/assets/stylesheets/`: the design, navy, white and mint in self-hosted Roboto,
  with a dark mode. `responsive/features/_tokens.scss` holds the colours, type and
  spacing; `responsive/custom.scss` lists what makes up the public stylesheet:
  these tokens, the theme's own styles (fonts, visitor), the page styles core
  keeps for its themes (base, shell, status, request, lists, pages, pro,
  core panels) and the app's feature styles. `admin-skin.scss` styles the admin
  pages.
* `app/assets/fonts/`: Roboto, served from the site (licence in `licenses/`).
* `app/assets/images/`: the question mark, favicon, share image and file-type icons.
* `app/assets/javascripts/`: the admin pages' scripts, without Bootstrap.
* `lib/views/`: the admin layout, page frame and help pages, and the app's
  hooks for its images and admin assets.
* `lib/help_site/`: an invented help pack, served at `/help` by core's help
  engine (see "Help pack" below).
* `lib/model_patches.rb`: the UK Acts' refusal sections.
* `locale-theme/en/app.po`: wording that replaces Alaveteli's.
* `data/`: the files the app's features read from a theme. Topics and the
  datasets they point to aren't files: core keeps them in its database, an admin edits
  them, and `sample_data:load` gives a fresh demo core's sample topics.
  * `foi_statistics/scotland-crosswalk.csv`: Scottish authorities' names in the
    Commissioner's figures, and their `sic:` tags.

Links in the data go to example.org.

## Using it

List the theme in `config/general.yml`:

    THEME_URLS:
      - 'https://github.com/FOIMonkey/nedervetil-test-theme.git'

A theme listed earlier wins over one listed later, so a site can list its own theme
first and keep this one's data, or leave this one out.

## Help pack

`/help` comes from `lib/help_site/`, through core's help engine ("Help pages"
in core's `doc/FORK.md` describes every file). The content is invented, like
the rest of the demonstration:

* `sections.yml`: the sections, in order, and the answers in each.
* `answers/<section>/<id>.md`: one answer each, with its question, the short
  answer search shows, and its related answers.
* `glossary.yml`: the words `[[word]]` explains.
* `signs.yml`: the sections' pictograms, beside core's, and the two a topic
  page shows beside its groups (`lib/views/topics/topics/_sign.html.erb`).

One answer has `extra: date-tool`, which adds core's reply deadline checker
under its text.

The views, search and styles are core's; the theme has none of its own. The
front page's title and the search box's example are core's strings, replaced
in `locale-theme/en/app.po` like any other wording.

There is nothing to build. Core reads these files as they are when the app
starts, so to change the pack, edit the files, list any new answer in
`sections.yml` and restart the app (in development the next request picks the
change up). `spec/fixtures/files/help_pack.yml` lists what the pack should
show (its pages, an article, a search, a related answer and a glossary
word): update it with the content, and run `spec/help_pack_spec.rb`.

## Tests

The theme's specs run in the app, with the theme loaded:

    bundle exec rspec lib/themes/nedervetil-test-theme/spec

## Licence

Based on alavetelitheme, copyright (c) 2011 mySociety, released under the MIT licence
(see `MIT-LICENSE`). Roboto is under the SIL Open Font License
(`licenses/Roboto-OFL.txt`).

## Sass modules

Ship this theme with the core Sass module migration. `responsive/main.scss`
loads `responsive/foundation_css` first, which configures Foundation from this
theme's settings, then the utility classes and page modules. The custom entry
loads `responsive/features/tokens_css` before the design and core feature modules.
`tokens` itself exports palette definitions; its `styles` mixin emits the custom
properties. The admin skin passes its own width and palettes to the scoped core
style mixins, keeping nested selectors and the public/admin boundary intact.

Core builds the stylesheets with Dart Sass and serves them with Propshaft
(core's `doc/THEME-ASSETS-UPGRADE.md`). `lib/alavetelitheme.rb` puts this
theme's Sass ahead of core's, names the admin skin for the build, and puts its
images, fonts and scripts ahead of core's. Compare core and your theme at
desktop and mobile widths after changes to module boundaries; loading a
dependency can change CSS order and `@extend` no longer reaches unrelated
downstream modules.
