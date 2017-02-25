sequential-number
=================

[![Build Status](http://img.shields.io/travis/tsuyoshiwada/sequential-number.svg?style=flat-square)](https://travis-ci.org/tsuyoshiwada/sequential-number)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://raw.githubusercontent.com/tsuyoshiwada/sequential-number/master/LICENSE)

An Atom package, to inputs sequential numbers across multiple cursors.

![screenshot](https://raw.githubusercontent.com/tsuyoshiwada/sequential-number/images/screenshot.gif)



## INSTALLATION

Search in the `sequential-number` from Install Packages.  
Please restart as necessary After the installation.


## USAGE


### Keymaps (Linux, Win, OS X)

<kbd>ctrl</kbd> + <kbd>alt</kbd> + <kbd>0</kbd> => Open the input panel !


### Syntax Rules

```
<start> <operator> <step> : <digit> : <radix>
```

| Key                                   | Default | Definition                                                                                                                                      |
| :------------------------------------ | :------ | :---------------------------------------------------------------------------------------------------------------------------------------------- |
| **start**                             | `""`    | It specifies the number that you start typing an integer.                                                                                       |
| **operator** <small>(optinal)</small> | `+`     | It specifies the generation rules of consecutive numbers in the `+` or `-`. The sign of the increment(`++`) and decrement(`--`) also available. |
| **step** <small>(optinal)</small>     | `1`     | It specifies the integer to be added or subtracted.                                                                                             |
| **digit** <small>(optinal)</small>    | `0`     | It specifies of the number of digits in the integer.                                                                                            |
| **radix** <small>(optinal)</small>    | `10`    | It specifies an integer between 2 and 36 that represents radix. Or increment alphabetically by `"a"` or `"A"`.                                  |



#### Examples

The following sample the cursor length is `5`.

```
# Input
=> 1
=> 1++
=> 1 + 1

# Output
1
2
3
4
5
```

```
# Input
=> 10 + 2

# Output
10
12
14
16
18
```

```
# Input
=> 0027 + 3

# Output
0027
0030
0033
0036
0039
```

```
# Input
=> 010 - 1
=> 010--

# Output
010
009
008
007
006
```

```
# Input
=> -10 + 1 : 2

# Output
-10
-09
-08
-07
-06
```

```
# Input
=> 0ff + 14 : 3 : 16

# Output
0ff
10d
11b
129
137
```

```
# Input
=> 0AB239 + 2 : 6 : 16

# Output
0AB239
0AB23B
0AB23D
0AB23F
0AB241
```

```
# Input
=> a + 2 : 1 : a

# Output
a
c
e
g
i
```

```
# Input
=> c + 20 : 3 : a

# Output
aac
aaw
aaq
abk
ace
```



## CUSTOMIZING KEYMAP

May be overriden for your favorite keystroke in your `keymap.cson`.

```coffeescript
# Open input panel
'atom-text-editor':
  'ctrl-alt-0': 'sequential-number:open'

# Close input panel
'.sequential-number atom-text-editor':
  'escape': 'sequential-number:close'
  'ctrl-c': 'sequential-number:close'
```



## AUTHOR
[tsuyoshiwada](https://github.com/tsuyoshiwada)



---



Bugs, feature requests and comments are more than welcome in the [issues](https://github.com/tsuyoshiwada/sequential-number/issues)
