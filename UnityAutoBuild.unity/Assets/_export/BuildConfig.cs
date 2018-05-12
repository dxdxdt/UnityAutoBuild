#if UNITY_EDITOR
using UnityEditor;

namespace FIX.UnityAutoBuild {
    public static class BuildConfig {
        public static readonly BuildPlayerOptions WIN_X86 = new BuildPlayerOptions() {
            target = BuildTarget.StandaloneWindows,
            options = BuildOptions.None
        };
        public static readonly BuildPlayerOptions WIN_X64 = new BuildPlayerOptions() {
            target = BuildTarget.StandaloneWindows64,
            options = BuildOptions.None
        };
        public static readonly BuildPlayerOptions LINUX = new BuildPlayerOptions() {
            target = BuildTarget.StandaloneLinuxUniversal,
            options = BuildOptions.None
        };
        public static readonly BuildPlayerOptions LINUX_HEADLESS = new BuildPlayerOptions() {
            target = BuildTarget.StandaloneLinux64,
            options = BuildOptions.EnableHeadlessMode
        };

        public static readonly BuildPlayerOptions ANDROID = new BuildPlayerOptions() {
            target = BuildTarget.Android,
            options = BuildOptions.None
        };
    }
}
#endif
