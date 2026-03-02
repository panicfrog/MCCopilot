import React, {useState} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  SafeAreaView,
  Alert,
} from 'react-native';
import {MccopilotRNModule} from 'react-native-mccopilot';

const ExampleRNApp: React.FC = () => {
  const [count, setCount] = useState<number>(0);
  const [cryptoResult, setCryptoResult] = useState<string>('');

  const testGetVersion = () => {
    try {
      const version = MccopilotRNModule.getVersion();
      setCryptoResult(`Rust 版本: ${version}`);
    } catch (e: any) {
      setCryptoResult(`错误: ${e.message}`);
    }
  };

  const stringToBuffer = (str: string): ArrayBuffer => {
    const buf = new Uint8Array(str.length);
    for (let i = 0; i < str.length; i++) {
      buf[i] = str.charCodeAt(i) & 0xff;
    }
    return buf.buffer;
  };

  const testSha256 = () => {
    try {
      const input = 'Hello, MCCopilot!';
      const data = stringToBuffer(input);
      const hash = MccopilotRNModule.cryptoHash('sha256', data);
      setCryptoResult(`SHA-256("${input}"):\n${hash}`);
    } catch (e: any) {
      setCryptoResult(`错误: ${e.message}`);
    }
  };

  const testAesGcm = () => {
    try {
      const nonceBuf = MccopilotRNModule.cryptoAesGcmGenerateNonce();
      const nonceHex = bufToHex(new Uint8Array(nonceBuf));

      const ivBuf = MccopilotRNModule.cryptoAesGenerateIv();
      const ivHex = bufToHex(new Uint8Array(ivBuf));

      setCryptoResult(
        `AES-GCM Nonce (${new Uint8Array(nonceBuf).length}B): ${nonceHex}\n` +
        `AES IV (${new Uint8Array(ivBuf).length}B): ${ivHex}`
      );
    } catch (e: any) {
      setCryptoResult(`错误: ${e.message}`);
    }
  };

  const testArgon2 = () => {
    try {
      const password = 'MySecretPassword123';
      const hash = MccopilotRNModule.cryptoArgon2Hash(password, undefined);
      const verified = MccopilotRNModule.cryptoArgon2Verify(password, hash);
      const wrongVerify = MccopilotRNModule.cryptoArgon2Verify('WrongPassword', hash);

      setCryptoResult(
        `Argon2 Hash:\n${hash}\n\n` +
        `正确密码验证: ${verified ? '通过' : '失败'}\n` +
        `错误密码验证: ${wrongVerify ? '通过' : '失败'}`
      );
    } catch (e: any) {
      setCryptoResult(`错误: ${e.message}`);
    }
  };

  const bufToHex = (bytes: Uint8Array): string => {
    return Array.from(bytes)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.title}>React Native 页面</Text>
          <Text style={styles.subtitle}>使用 TypeScript 编写</Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>计数器示例</Text>
          <Text style={styles.counterText}>{count}</Text>
          <View style={styles.buttonRow}>
            <TouchableOpacity
              style={[styles.button, styles.decrementButton]}
              onPress={() => setCount(count - 1)}>
              <Text style={styles.buttonText}>-</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.button, styles.incrementButton]}
              onPress={() => setCount(count + 1)}>
              <Text style={styles.buttonText}>+</Text>
            </TouchableOpacity>
          </View>
          <TouchableOpacity
            style={[styles.button, styles.resetButton]}
            onPress={() => setCount(0)}>
            <Text style={styles.buttonText}>重置</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>Rust 加密测试 (NitroModule)</Text>
          <View style={styles.buttonRow}>
            <TouchableOpacity
              style={[styles.button, styles.cryptoButton]}
              onPress={testGetVersion}>
              <Text style={styles.buttonText}>版本号</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.button, styles.cryptoButton]}
              onPress={testSha256}>
              <Text style={styles.buttonText}>SHA-256</Text>
            </TouchableOpacity>
          </View>
          <View style={styles.buttonRow}>
            <TouchableOpacity
              style={[styles.button, styles.cryptoButton]}
              onPress={testAesGcm}>
              <Text style={styles.buttonText}>AES-GCM</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.button, styles.cryptoButton]}
              onPress={testArgon2}>
              <Text style={styles.buttonText}>Argon2</Text>
            </TouchableOpacity>
          </View>
          {cryptoResult ? (
            <View style={styles.resultBox}>
              <Text style={styles.resultText} selectable>{cryptoResult}</Text>
            </View>
          ) : null}
        </View>

        <View style={styles.infoCard}>
          <Text style={styles.infoTitle}>技术栈信息</Text>
          <Text style={styles.infoText}>• React Native 0.77</Text>
          <Text style={styles.infoText}>• TypeScript 5.6</Text>
          <Text style={styles.infoText}>• NitroModules 0.34.1 (C++ JSI)</Text>
          <Text style={styles.infoText}>• Rust 加密 (MccopilotBridge)</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollContent: {
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 30,
    marginTop: 20,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 24,
    marginBottom: 20,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  cardTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#333',
    marginBottom: 20,
    textAlign: 'center',
  },
  counterText: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#007AFF',
    textAlign: 'center',
    marginBottom: 20,
  },
  buttonRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  button: {
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 100,
  },
  incrementButton: {
    backgroundColor: '#34C759',
    flex: 1,
    marginLeft: 8,
  },
  decrementButton: {
    backgroundColor: '#FF3B30',
    flex: 1,
    marginRight: 8,
  },
  resetButton: {
    backgroundColor: '#007AFF',
  },
  buttonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  cryptoButton: {
    backgroundColor: '#5856D6',
    flex: 1,
    marginHorizontal: 4,
  },
  resultBox: {
    backgroundColor: '#f0f0f0',
    borderRadius: 8,
    padding: 12,
    marginTop: 12,
  },
  resultText: {
    fontSize: 13,
    color: '#333',
    fontFamily: 'Menlo',
    lineHeight: 20,
  },
  infoCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  infoTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 12,
  },
  infoText: {
    fontSize: 15,
    color: '#666',
    marginBottom: 8,
    lineHeight: 22,
  },
});

export default ExampleRNApp;

