# Adding webpack 4.0.x

Mars 2018.

As I choosed not to install brunch, I will add webpack 4 as a replacement. I am using yarn, but this can be done with npm as well. This is not a guide on using Webpack 4, just a simple way to add Webpack to a Phoenix umbrella application.

References:

* [Notes on attempt to upgrade to webpack 4](https://gist.github.com/gricard/e8057f7de1029f9036a990af95c62ba8)
* [Code splitted css bundle examples](https://github.com/webpack/webpack/blob/master/examples/code-splitted-css-bundle/README.md)

Additional packages, needed for configuration.

* [webpack-cli](https://github.com/webpack/webpack/releases/tag/v4.0.0-beta.0)
* [extract-text-webpack-plugin@next](https://github.com/webpack-contrib/extract-text-webpack-plugin/tree/next)

The following steps are defined from the root of the project.

## 1. Initialize assets and package.json

```bash
$ mkdir assets
$ cd assets
$ yarn init -y
```

This will create a package.json file. It is now possible to add some scripts.

I added watch script to be used later by Phoenix watcher. Although it does the same as build:dev.

```bash
$ vim package.json
  "scripts": {
    "stats": "webpack --profile --json > stats.json",
    "watch": "webpack --watch --mode development",
    "build:dev": "webpack --watch --mode development",
    "build:prod": "NODE_ENV=production webpack --mode production",
    "lint": "eslint src"
  },
```

After creating assets, the rest is performed inside this folder.

## 2. Configure .gitignore

To avoid persisting node_modules, log files, and .DS_Store (Mac only), create a .gitignore file and add...

```bash
$ vim .gitignore
npm-debug.log
yarn-error.log
/node_modules
.DS_Store
```

## 3. Add packages

The first packages needed are the following dev dependencies. Versions are subject to change.

    "css-loader": "^0.28.10",
    "extract-text-webpack-plugin": "^4.0.0-beta.0",
    "file-loader": "^1.1.10",
    "style-loader": "^0.20.2",
    "webpack": "^4.0.1",
    "webpack-cli": "^2.0.9"

```bash
$ yarn add -D css-loader file-loader style-loader webpack webpack-cli extract-text-webpack-plugin@next
```

## 4. Babel

The list of packages may vary a lot depending on which framework You will be using. Here is a simple config for React.

```bash
$ yarn add -D babel-core babel-eslint babel-loader babel-preset-env babel-preset-react babel-preset-stage-0 
```

## 5. Eslint

To install eslint

```bash
$ yarn add -D eslint
```

To configure eslint, You need to select from multiple questions. 

For this example, I choosed Airbnb, React, YAML but You are free to select what You prefer.

```bash
$ eslint --init
? How would you like to configure ESLint? 
  Answer questions about your style 
❯ Use a popular style guide 
  Inspect your JavaScript file(s) 
? Which style guide do you want to follow? 
  Google 
❯ Airbnb 
  Standard
? Do you use React? (y/N) Y
? What format do you want your config file to be in? 
  JavaScript 
❯ YAML 
  JSON
Checking peerDependencies of eslint-config-airbnb@latest
? The style guide "airbnb" requires eslint@^4.9.0. You are currently using eslint@4.7.2.
  Do you want to upgrade? Yes
Installing eslint-config-airbnb@latest, eslint@^4.9.0, eslint-plugin-import@^2.7.0, eslint-plugin-jsx-a11y@^6.0.2, eslint-plugin-react@^7.4.0
```

This will create .eslintrc.yml file.

Now, to test syntax, You can run

```bash
$ yarn lint
yarn run v1.3.2
$ eslint src
✨  Done in 0.43s.
```

## 6. Configure Webpack 4

Here is a simple config file, that will output bundle into app_umbrella/apps/app_web/priv/static/js and css into corresponding folder.

```bash
$ vim webpack.config.js
// Webpack 4 config
const debug = process.env.NODE_ENV !== 'production';

const Webpack = require('webpack');
const path = require('path');
const ROOT_PATH = path.resolve(__dirname);
const SRC_PATH = path.resolve(ROOT_PATH, 'src');
const BUILD_PATH = path.resolve(ROOT_PATH, '../apps/app_web/priv/static');

// Use next version to be compatible with Webpack 4!
// https://github.com/webpack-contrib/extract-text-webpack-plugin/tree/next
const ExtractTextPlugin = require('extract-text-webpack-plugin');

let commonPlugins = [
  new ExtractTextPlugin({
    filename: 'css/styles.css',
    allChunks: true,
  }),
]

module.exports = {
  context: __dirname,
  devtool: debug ? 'inline-sourcemap' : false,
  entry: {
    bundle: SRC_PATH + '/index',
  },
  output: {
    path: BUILD_PATH,
    publicPath: '',
    filename: 'js/[name].js',
    chunkFilename: '[name].bundle.js',
  },
  plugins: debug ? commonPlugins : [
    ...commonPlugins,
    // Add production plugins here!
  ],
  resolve: {
    extensions: ['.js', '.jsx'],
  },
  module: {
    rules: [
      // Load javascripts
      {
        test: /\.jsx?$/,
        include: SRC_PATH,
        exclude: /node_modules/,
        loader: 'babel-loader',
        options: {
          presets: ['env', 'react', 'stage-0']
        },
      },
      // Load stylesheets
      {
        test: /(\.css)$/,
        use: ExtractTextPlugin.extract({
          fallback: 'style-loader',
          use: 'css-loader',
        }),
      },
      // Load images
      {
        test: /\.(png|svg|jpg|gif)$/,
        loader: 'file-loader',
      },
      // Load fonts
      {
        test: /\.(woff|woff2|eot|ttf|otf)$/,
        loader: 'file-loader',
      },
    ],
  },
};
```

## 7. Add some samples

In order to test it, You need to add a src folder, that will include index.js as the main entry point for your bundle. And app.css that will be bundled into a separate file (css/styles.css)

```bash
$ mkdir src
$ vim src/app.css
body {
  color: red;
}
$ vim src/index.js
import './app.css';
const world = 'world';
console.log(`hello ${world}`);
```

The index file is just a test to see if css get created, and to check if babel is transpiling correctly.

Now try running ...

```bash
$ yarn build:prod
yarn run v1.3.2
$ NODE_ENV=production webpack --mode production
Hash: 7240df505aba723eac41
Version: webpack 4.0.1
Time: 1708ms
Built at: 01.03.2018 05:11:08
         Asset       Size  Chunks             Chunk Names
  js/bundle.js  607 bytes       0  [emitted]  bundle
css/styles.css   22 bytes       0  [emitted]  bundle
Entrypoint bundle = js/bundle.js css/styles.css
   [0] ./src/app.css 41 bytes {0} [built]
   [1] ./src/index.js 89 bytes {0} [built]
Child extract-text-webpack-plugin node_modules/extract-text-webpack-plugin/dist node_modules/css-loader/index.js!src/app.css:
    Entrypoint undefined = extract-text-webpack-plugin-output-filename
       [1] ./node_modules/css-loader!./src/app.css 183 bytes {0} [built]
        + 1 hidden module
✨  Done in 2.75s.
```

... and You should see styles.css, bundle.js newly created files into Phoenix priv/static


## 8. Configure Phoenix

Leave the assets folder and go into web part.

Configure watchers

```bash
$ cd ../apps/app_web/
$ vim config/dev.exs

    ...
    watchers: [yarn: ["run", "watch", cd: Path.expand("../../../assets", __DIR__)]]
    ...
```

Configure layout to use the generated files

```bash
$ vim lib/templates/layout/app.html.eex

    ...
    <link rel="stylesheet" href="<%= static_path(@conn, "/css/styles.css") %>">
    ...
    <script src="<%= static_path(@conn, "/js/bundle.js") %>"></script>
    ...
```

You can see that when server is started, webpack is watching files...

```bash
$ iex -S mix phx.server
Erlang/OTP 20 [erts-9.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:10] [hipe] [kernel-poll:false]

[info] Running AppWeb.Endpoint with Cowboy using http://0.0.0.0:4000
Interactive Elixir (1.6.1) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> yarn run v1.3.2
$ webpack --watch --mode development

Webpack is watching the files…

Hash: 6096f3c935c9a5898493
Version: webpack 4.0.1
Time: 919ms
Built at: 01.03.2018 05:21:13
         Asset       Size  Chunks             Chunk Names
  js/bundle.js   6.92 KiB  bundle  [emitted]  bundle
css/styles.css  213 bytes  bundle  [emitted]  bundle
Entrypoint bundle = js/bundle.js css/styles.css
[./src/app.css] 41 bytes {bundle} [built]
[./src/index.js] 89 bytes {bundle} [built]
Child extract-text-webpack-plugin node_modules/extract-text-webpack-plugin/dist node_modules/css-loader/index.js!src/app.css:
    Entrypoint undefined = extract-text-webpack-plugin-output-filename
    [./node_modules/css-loader/index.js!./src/app.css] ./node_modules/css-loader!./src/app.css 183 bytes {0} [built]
        + 1 hidden module
```

Updating your css or js files will reload automaticaly.


## 9. Exclude dynamic files from git repo

It is not useful to save those files to github, so just ignore them.

From the web part (apps/app_web), update .gitignore file.

```bash
$ vim .gitignore

    ...
    /priv/static/css/styles.css
    /priv/static/js/bundle.js
    ...
```

## 10. Final step

It's time to save the whole project, go to the root, and run

```bash
$ cd ../../
$ git add .
$ git commit -m "Add webpack 4 docs"
$ git push
```

This section does not cover using React. It will just guide You to assets bundling w/ Phoenix and Webpack 4. It does not use more loader than needed for demo. 

You could add loader for SASS, etc.