import styles from "./critical.css";

// Return `is1x1` style by default.
export function CSSClass(aspectRatio) {
  const className = `is${aspectRatio}`;
  return styles[className] ? styles[className] : styles.is1x1;
}
