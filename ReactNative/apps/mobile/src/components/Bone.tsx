import React, {useEffect, useRef} from 'react';
import {Animated, StyleSheet} from 'react-native';

const Bone: React.FC<{style?: any}> = ({style}) => {
  const opacity = useRef(new Animated.Value(0.3)).current;

  useEffect(() => {
    const anim = Animated.loop(
      Animated.sequence([
        Animated.timing(opacity, {
          toValue: 0.7,
          duration: 800,
          useNativeDriver: true,
        }),
        Animated.timing(opacity, {
          toValue: 0.3,
          duration: 800,
          useNativeDriver: true,
        }),
      ]),
    );
    anim.start();
    return () => anim.stop();
  }, [opacity]);

  return <Animated.View style={[styles.bone, {opacity}, style]} />;
};

const styles = StyleSheet.create({
  bone: {
    backgroundColor: '#e0e0e0',
  },
});

export default Bone;
