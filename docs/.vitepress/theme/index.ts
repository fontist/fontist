import DefaultTheme from "vitepress/theme";
import "./style.css";
import WithinHero from "./components/WithinHero.vue";
import HeroCodeBlock from "./components/HeroCodeBlock.vue";

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component("WithinHero", WithinHero);
    app.component("HeroCodeBlock", HeroCodeBlock);
  },
};
