import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as Repack from '@callstack/repack';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const reactNativeRoot = path.resolve(__dirname, '../..');

export default Repack.defineRspackConfig({
  context: __dirname,
  entry: './index.tsx',
  resolve: {
    ...Repack.getResolveOptions(),
    modules: [path.resolve(reactNativeRoot, 'node_modules'), 'node_modules'],
  },
  module: {
    rules: [
      {
        test: /\.[cm]?[jt]sx?$/,
        type: 'javascript/auto',
        use: {
          loader: '@callstack/repack/babel-swc-loader',
          parallel: true,
          options: {},
        },
      },
      ...Repack.getAssetTransformRules(),
    ],
  },
  optimization: {
    splitChunks: {
      chunks: 'async',
      minSize: 0,
    },
  },
  output: {
    chunkFilename: '[name].chunk.bundle',
  },
  plugins: [
    new Repack.RepackPlugin({
      extraChunks: [
        {
          type: 'remote',
          outputPath: path.resolve(reactNativeRoot, 'build/outputs/ios/remotes'),
        },
      ],
    }),
  ],
});
