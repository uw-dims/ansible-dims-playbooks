#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 tw=0 noet :
#
# Document: ansible-dims-playbooks
# This documentation build configuration file was created from
# a cookiecutter template. It is based on output derived from
# the output of sphinx-quickstart.
#
# This file is execfile()d with the current directory set to its
# containing dir.
#
# Note that not all possible configuration values are present in this
# autogenerated file.
#
# All configuration values have a default; values that are commented out
# serve to show the default.

import sys
import os
import shlex
from sphinx import __version__

# ReadTheDocs configuration setting:

on_rtd = os.environ.get('READTHEDOCS') == "True"
if on_rtd:
    html_theme = 'default'
else:
    html_theme = 'sphinx_rtd_theme'


# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#sys.path.insert(0, os.path.abspath('.'))

# -- General configuration ------------------------------------------------

# If your documentation needs a minimal Sphinx version, state it here.
#needs_sphinx = '1.0'

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
    'sphinx.ext.mathjax',
    'sphinx.ext.graphviz',
    'sphinx.ext.ifconfig',
    'sphinx.ext.githubpages',
]

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# The suffix(es) of source filenames.
# You can specify multiple suffix as a list of string:
#
# source_suffix = ['.rst', '.md']
source_suffix = '.rst'

# The encoding of source files.
source_encoding = 'utf-8-sig'

# The master toctree document.
master_doc = 'index'

# General information about the project.
project = u'DIMS Ansible playbooks'
author = u'Dave Dittrich'
copyright = u'2017, University of Washington'

# The version info for the project you're documenting, acts as replacement for
# |version| and |release|, also used in various other places throughout the
# built documents.
#
# The short X.Y version.
version = '2.1.0'
# The full version, including alpha/beta/rc tags.
release = '2.1.0'

# The language for content autogenerated by Sphinx. Refer to documentation
# for a list of supported languages.
#
# This is also used if you do content translation via gettext catalogs.
# Usually you set "language" from the command line for these cases.
#language = None

# There are two options for replacing |today|: either, you set today to some
# non-false value, then it is used:
#today = ''
# Else, today_fmt is used as the format for a strftime call.
#today_fmt = '%B %d, %Y'

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This patterns also effect to html_static_path and html_extra_path
exclude_patterns = []


# If true, sectionauthor and moduleauthor directives will be shown in the
# output. They are ignored by default.
show_authors = True

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# If true, `todo` and `todoList` produce output, else they produce nothing.

if on_rtd or os.environ.get('INCLUDETODOS') == "False":
    todo_include_todos = False
else:
    todo_include_todos = True

# -- Options for HTML output ----------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'sphinx_rtd_theme'

# Theme options are theme-specific and customize the look and feel of a theme
# further.  For a list of options available for each theme, see the
# documentation.
#html_theme_options = {}

# Add any paths that contain custom themes here, relative to this directory.
#html_theme_path = []

# The name for this set of Sphinx documents.  If None, it defaults to
# "<project> v<release> documentation".
#html_title = None

# A shorter title for the navigation bar.  Default is the same as html_title.
#html_short_title = None

# The name of an image file (relative to this directory) to place at the top
# of the sidebar.
html_logo = 'UW-logo.png'

# The name of an image file (within the static path) to use as favicon of the
# docs.  This file should be a Windows icon file (.ico) being 16x16 or 32x32
# pixels large.
html_favicon = 'UW-logo-32x32.ico'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']



# Output file base name for HTML help builder.
htmlhelp_basename = 'ansible-dims-playbooksdoc'


# -- Options for LaTeX output ---------------------------------------------

latex_elements = {
    # The paper size ('letterpaper' or 'a4paper').
    #'papersize': 'letterpaper',

    # The font size ('10pt', '11pt' or '12pt').
    #'pointsize': '10pt',

    # Additional stuff for the LaTeX preamble.
    #
    # The following comes from
    # https://github.com/rtfd/readthedocs.org/issues/416
    # and http://www.utf8-chartable.de/unicode-utf8-table.pl?start=9472&names=-
    #
    'preamble': "".join((
        '\usepackage{pifont}',                # To get Dingbats
        '\DeclareUnicodeCharacter{00A0}{ }',  # NO-BREAK SPACE
        '\DeclareUnicodeCharacter{2014}{\dash}', # LONG DASH
        '\DeclareUnicodeCharacter{251C}{+}',  # BOX DRAWINGS LIGHT VERTICAL AND RIGHT
        '\DeclareUnicodeCharacter{2514}{+}',  # BOX DRAWINGS LIGHT UP AND RIGHT
        '\DeclareUnicodeCharacter{1F37A}{ }', # Beer emoji (just turn into space for now)
        '\DeclareUnicodeCharacter{2588}{\textblock}',  # SOLID TEXT BLOCK
        '\DeclareUnicodeCharacter{25CF}{\ding{108}}',  # Dingbat 108 (black circle)
    )),
}

# Grouping the document tree into LaTeX files. List of tuples
# (source start file, target name, title,
#  author, documentclass [howto, manual, or own class]).
latex_documents = [
  (master_doc,
   'ansible-dims-playbooks.tex',
   u'DIMS Ansible playbooks Documentation',
   u'Dave Dittrich',
   'manual'),
]

# The name of an image file (relative to this directory) to place at
# the top of the title page.
latex_logo = 'UW-logo.png'

# For "manual" documents, if this is true, then toplevel headings
# are parts, not chapters.
#latex_use_parts = False

# If true, show page references after internal links.
#latex_show_pagerefs = False

# If true, show URL addresses after external links.
#latex_show_urls = False

# Documents to append as an appendix to all manuals.
#latex_appendices = ['appendices']

# If false, no module index is generated.
#latex_domain_indices = True


# -- Options for manual page output ------------------------------------

# One entry per manual page. List of tuples
# (source start file, name, description, authors, manual section).
man_pages = [
    (master_doc,
     'ansible-dims-playbooks',
     u'DIMS Ansible playbooks',
     [u'Dave Dittrich'],
     1)
]

# If true, show URL addresses after external links.
#man_show_urls = False


# -- Options for Texinfo output -------------------------------------------

# Grouping the document tree into Texinfo files. List of tuples
# (source start file, target name, title, author,
#  dir menu entry, description, category)
texinfo_documents = [
    (master_doc,
     'ansible-dims-playbooks',
     u'DIMS Ansible playbooks',
     u'Dave Dittrich',
     'ansible-dims-playbooks',
     'Ansible playbooks for DIMS system build/configuration',
     'Miscellaneous'),
]

# Documents to append as an appendix to all manuals.
#texinfo_appendices = []

# If false, no module index is generated.
#texinfo_domain_indices = True

# How to display URL addresses: 'footnote', 'no', or 'inline'.
#texinfo_show_urls = 'footnote'

# If true, do not generate a @detailmenu in the "Top" node's menu.
#texinfo_no_detailmenu = False

# -- Options for Epub output ----------------------------------------------

# Bibliographic Dublin Core info.
epub_title = project
epub_author = author
epub_publisher = author
epub_copyright = copyright

# The basename for the epub file. It defaults to the project name.
epub_basename = u'ansible-dims-playbooks'

# The unique identifier of the text. This can be a ISBN number
# or the project homepage.
#
# epub_identifier = ''

# A unique identification for the text.
#
# epub_uid = ''

# A list of files that should not be packed into the epub file.
epub_exclude_files = ['search.html']

git_branch = os.environ.get('GITBRANCH', "develop")
git_tag = os.environ.get('GITTAG', "latest")

#os.environ['DOCSURL'] = "file://{}".format(os.environ.get('GIT'))

if os.environ.get('DOCSURL') is None:
    if not on_rtd:
        os.environ['DOCSURL'] = "http://app.devops.develop:8080/docs/{}/html".format(git_branch)

intersphinx_cache_limit = -1   # days to keep the cached inventories (0 == forever)
if on_rtd:
    intersphinx_mapping = {
        'dimssr': ("https://dims-sr.readthedocs.io/en/{0}".format(git_tag), None),
    }
else:
    intersphinx_mapping = {
        'dimssr': ("{}/dims-sr".format(os.environ['DOCSURL']), None),
    }
