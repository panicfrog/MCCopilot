import {AppRegistry} from 'react-native';
import ExampleRNApp from './src/ExampleRNApp';
import SecondRNApp from './src/SecondRNApp';

// 注册多个React Native应用模块
AppRegistry.registerComponent('ExampleRNApp', () => ExampleRNApp);
AppRegistry.registerComponent('SecondRNApp', () => SecondRNApp);

