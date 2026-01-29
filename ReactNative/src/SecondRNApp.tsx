import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
} from 'react-native';

const SecondRNApp: React.FC = () => {
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.header}>
          <Text style={styles.title}>第二个 RN 模块</Text>
          <Text style={styles.subtitle}>共享同一个 Bridge</Text>
        </View>

        <View style={styles.card}>
          <Text style={styles.emoji}>🚀</Text>
          <Text style={styles.description}>
            这是另一个独立的React Native模块，它与ExampleRNApp共享同一个Bridge实例，
            但可以有完全不同的UI和逻辑。
          </Text>
        </View>

        <View style={styles.featureList}>
          <Text style={styles.featureTitle}>特性：</Text>
          <FeatureItem text="独立的组件树" />
          <FeatureItem text="共享的JavaScript运行时" />
          <FeatureItem text="更高的性能和更低的内存占用" />
          <FeatureItem text="便于模块化开发" />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

interface FeatureItemProps {
  text: string;
}

const FeatureItem: React.FC<FeatureItemProps> = ({text}) => (
  <View style={styles.featureItem}>
    <Text style={styles.bullet}>✓</Text>
    <Text style={styles.featureText}>{text}</Text>
  </View>
);

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
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  emoji: {
    fontSize: 64,
    marginBottom: 16,
  },
  description: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    lineHeight: 24,
  },
  featureList: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
  },
  featureTitle: {
    fontSize: 20,
    fontWeight: '600',
    color: '#333',
    marginBottom: 16,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  bullet: {
    fontSize: 20,
    color: '#34C759',
    marginRight: 12,
    fontWeight: 'bold',
  },
  featureText: {
    fontSize: 16,
    color: '#666',
    flex: 1,
  },
});

export default SecondRNApp;

