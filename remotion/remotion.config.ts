import { Config } from "@remotion/cli/config";
import fs from "node:fs";

// Cloud VM: remotion.media (Chrome download host) is not reachable, use the preinstalled Playwright headless shell.
const PW = "/opt/pw-browsers/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell";
if (!process.env.CHROME && fs.existsSync(PW)) Config.setBrowserExecutable(PW);
else if (process.env.CHROME) Config.setBrowserExecutable(process.env.CHROME);
