
# FadestormLib

FadestormLib is small but powerful library for the Lua 5.1+ programming language. It is designed to implement a variety of high-level features found in other languages.

## Table of Contents

- [About](#about)
- [Overview](#feature-overview)
- [Installation](#installation)
- [API / Wiki](https://github.com/KevinTyrrell/FadestormLib/wiki)
- [Changelog](#changelog)
- [Roadmap](#roadmap)
- [License](#license)

## About

##### Author: [Kevin Tyrrell](https://github.com/KevinTyrrell) --- Latest Release: [Releases](https://github.com/KevinTyrrell/FadestormLib/releases/latest)
<!--[[ __VERSION_MARKER__ ]]-->
#### Current Build: 2024-01-24 | Version: v7.0.4

While Lua is a small and versatile language, its standard library lacks the expansive tool-set programmers are accustomed to when working with other languages. This library intends to fill in some of those gaps by providing a general array of tools. The features in this library may not be idiomatic to Lua, but they are aimed to be intuitive to use and to reduce code ambiguity while improving maintainability. The themes of the library include, but are not limited to: **functional programming**, **strict typing**, **object oriented design**, and **immutability**.

This library was [originally made as a utility for use with World of Warcraft addons](https://github.com/KevinTyrrell/WoWProfessionOptimizer) and is maintained to be compatible with stand-alone Lua, Roblox, etc. See the [Installation](#installation) section for more information on configuration for your environment.


## Feature Overview

- **Feature 1:**
  A powerful module for seamless data integration, ensuring efficient handling and processing.

- **Feature 2:**
  Robust error-handling mechanisms to enhance the reliability and stability of your applications.
   
```
>>>>>                   Features at a glance                   <<<<<
```
 
| **Feature** | **Description**                                                      |
|-------------|----------------------------------------------------------------------|
| Streams     | `filter`, `map`, `flat_map`, `for_each`, `collect`, `grouping`, ...  |
| Enums       | `ordinal`, *Comparable*, `Enum.values`, `Enum.size`, ...             |
| Errors      | `ILLEGAL_ARGUMENT`, `TYPE_MISMATCH`, `NIL_POINTER`, ...              |
| Types       | `local my_num = Type.NUMBER("5")` --> `Error.TYPE_MISMATCH`          |
| Colors      | `Color.PINK("Hello")` --> `"|cFFFFC0CBHello|r"`, `complement`        |
| Table       | `read_only`, `set`, quicksort3, `put_default` / `put_compute`        |

```
>>>>>                   Features Explained                   <<<<<
```

- **Streams:** modeled closely to [Java 8's Stream API](https://docs.oracle.com/javase/8/docs/api/java/util/stream/Stream.html). Allow you to manipulate data considerably easier than using an iterative approach, at the cost of very slight functional overhead. Stream calls can be chained together for for multiple intermediate operations before a singular terminal operation.
- **Enums:** Imitation of [Java's Enum](https://docs.oracle.com/javase/8/docs/api/java/lang/Enum.html). Enums are formal classes with static members. Enums can identify table instances by table reference, by string, or by `ordinal`. Enums and each of their instances have their own members and are **immutable** after construction. 
- **Errors:** replacement for `error()`. Explicit & standardized route to throw runtime errors/exceptions.
- **Types:** replacement for `type()`. Performs type-checking and type assertions in a convenient manner.
- **Colors:** enumeration of common colors & color-codes. Provides simplistic way to paint strings.
- **Table:** enables **read-only** tables. Contains various other `table`-related utilities.

## Installation

```
markdown-pages/
|---assets/
|------user/
|	   |---favicon.png
|	   |---example.png
|---pages/
|	|---sample-page.md
|	|---sample-page-2.md
|---index.html
|---README.md
```

### README.md

The `README.md` file will provide the content for the homepage of your site. Simply author the file using [Markdown syntax](https://www.markdownguide.org/basic-syntax/).

### index.html

The `index.html` file does the magic of converting Markdown to HTML. It will also look for a heading level 1 (h1) on the current page and prepend it to the site title. You can add your site title by modifying this line in the header:

```
&lt;title&gt;Markdown Pages&lt;/title&gt;
```

There are other lines in the header that you may want to edit as well, such as the meta description and the favicon image name/location.


### Pages

Additional pages can be added to the `pages` directory, using Markdown files. To add a link to an additional page, for example, `sample-page.md`, the following link structure can be used: 

```
Check out the [sample page](?page=sample-page)
```

Check out the [sample page](?page=sample-page) (link will work on the rendered site, not github.com).

### Assets

Images and other files can be added to the `assets/user` directory and linked as needed. 

## Images

Images can be included with Markdown as they normally are:

```
![markdown logo](assets/user/markdown.svg)
```

And image sizing configuration is available through the [parseImgDimensions](https://showdownjs.com/docs/available-options/#parseimgdimensions) option in Showdown JS:

```
![bar](bar.jpg =100x*)    sets width to 100px and height to "auto"
![foo](foo.jpg =100x80)   sets width to 100px and height to 80px
![baz](baz.jpg =80%x5em)  sets width to 80% and height to 5em
```

## Styles

### Dark/Light Mode

The site will include a dark/light mode toggle button by default. When adding images to a page, consider adding images that will contrast well against both a light and dark background.

### Syntax Highlighting

Syntax highlighting will automatically be applied to code blocks, for example:

```
def my_function():
  fruits = ['orange', 'apple', 'pear', 'kiwi', 'banana']
  for fruit in fruits:
    if fruit == 'banana':
        print(fruit)

my_function()
```

## Limitations

- **Local Development** - since the site uses XMLHttpRequest to grab content, a local web server will be needed if you want to test things locally, e.g. `python -m http.server`. However, editing files directly on a server/GitHub is part of the convenience/fun.
- **Limited element options** - if the element you're trying to use exists in Markdown, the converter should be able to render it as HTML, but this will exclude a lot of more advanced HTML elements.  
- **No custom layouts** - Markdown used in this way is fairly linear, so you won't be able to do a columns and fancy layouts without extra work.

## Todo

- Add a header/menu and footer section in `index.html` that can be populated from Markdown files?
- Add a classless CSS theme picker [[1](https://github.com/dohliam/dropin-minimal-css)] [[2](https://github.com/dandalpiaz/classless-css-picker)]
    - Find/create a classless a11y CSS framework?
- Escape HTML in code blocks using JS, so that this doesn't have to be done in code blocks to render correctly
- Implement more [Showdown JS options](https://github.com/showdownjs/showdown/wiki/Showdown-Options)
- Move pages out of 'pages' directory so that GitHub and hosted site can find assets using the same relative paths?
