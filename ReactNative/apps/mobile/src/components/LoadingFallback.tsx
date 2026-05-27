import React from 'react';
import {View, StyleSheet} from 'react-native';
import Bone from './Bone';

const LoadingFallback: React.FC = () => (
  <View style={styles.container}>
    {/* Header */}
    <View style={styles.header}>
      <Bone style={{width: 180, height: 28, borderRadius: 6}} />
      <Bone style={{width: 120, height: 16, borderRadius: 4, marginTop: 10}} />
    </View>

    {/* Card */}
    <View style={styles.card}>
      <Bone
        style={{width: 56, height: 56, borderRadius: 28, marginBottom: 16}}
      />
      <Bone style={{width: '90%', height: 14, borderRadius: 4}} />
      <Bone style={{width: '70%', height: 14, borderRadius: 4, marginTop: 8}} />
      <Bone style={{width: '80%', height: 14, borderRadius: 4, marginTop: 8}} />
    </View>

    {/* Feature list */}
    <View style={styles.featureList}>
      <Bone
        style={{width: 80, height: 20, borderRadius: 4, marginBottom: 20}}
      />
      {[0.6, 0.85, 0.7, 0.9].map((widthRatio, i) => (
        <View key={i} style={styles.featureRow}>
          <Bone style={{width: 20, height: 20, borderRadius: 4}} />
          <Bone style={{flex: widthRatio, height: 14, borderRadius: 4}} />
        </View>
      ))}
    </View>
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 30,
    marginTop: 20,
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
  featureRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 12,
  },
});

export default LoadingFallback;
