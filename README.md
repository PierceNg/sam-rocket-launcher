# SAM Pattern Rocket Launcher

This is an implementation of the [SAM pattern](https://sam.js.org/) [rocket launcher](https://sam.js.org/#rocket) example for
[pas2js](https://wiki.freepascal.org/pas2js).

## Files

- `index.html`
- `bulmaswatch.min.css`
- `samrocket.lpr` - Pascal source code
- `samrocket.js` - Pascal source code transpiled to Javascript by pas2js

## Running

Start a web server in this directory, say, using Python:

```
% python3 -m http.server 8080
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
```

Visit `localhost:8000` with your web browser.

## Compiling

```
% pas2js samrocket.lpr
Pas2JS Compiler version 2.3.1 [2022/12/10] for Linux x86_64
Copyright (c) 2022 Free Pascal team.
...
Info: 30704 lines in 14 files compiled, 0.6 secs
```

# Copyright and License

Copyright (c) 2023 Pierce Ng. My code is released under MIT license. The file `bulmaswatch.min.css` is also under MIT license.
See `LICENSE.md` for details.

