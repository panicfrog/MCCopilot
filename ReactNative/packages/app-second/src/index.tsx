import React from 'react';
import {View, Text, StyleSheet, ScrollView} from 'react-native';
import {SafeAreaView, SafeAreaProvider} from 'react-native-safe-area-context';

const SecondRNApp: React.FC = () => {
  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.container}>
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <View style={styles.header}>
            <Text style={styles.title}>远程模块 v7 (monorepo)</Text>
            <Text style={styles.subtitle}>通过 API 动态加载</Text>
          </View>

          <View style={styles.card}>
            <Text style={styles.emoji}>📦</Text>
            <Text style={styles.description}>
              这个页面是从远程服务器动态下载的！chunk 通过 mccopilot-server
              分发， 本地缓存后离线也可用。
            </Text>
          </View>

          <View style={styles.featureList}>
            <Text style={styles.featureTitle}>动态加载流程：</Text>
            <FeatureItem text="检查本地缓存" />
            <FeatureItem text="获取远程 manifest" />
            <FeatureItem text="下载最新 chunk" />
            <FeatureItem text="缓存到本地文件" />
            <FeatureItem text="hash 校验自动更新" />
          </View>
        </ScrollView>
      </SafeAreaView>
    </SafeAreaProvider>
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
