// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

pragma Singleton

import QtQuick

QtObject {
    id: constants

    // APPLICATION IDENTITY

    readonly property string appName: "YoungLion Calendar"
    readonly property string appShortName: "Calendar"
    readonly property string appVersion: "0.2.0"
    readonly property string organizationName: "YoungLion"
    readonly property string organizationDomain: "younglion.xyz"
    readonly property string applicationId: "xyz.younglion.Calendar"

    // Default Qt Design Studio canvas dimensions.
    // These are NOT fixed sizes for the actual window.
    readonly property int width: 1280
    readonly property int height: 800

    readonly property int minimumWindowWidth: 320
    readonly property int minimumWindowHeight: 480

    readonly property int preferredDesktopWidth: 1200
    readonly property int preferredDesktopHeight: 800

    readonly property int preferredMobileWidth: 390
    readonly property int preferredMobileHeight: 844

    // APPEARANCE AND USER PREFERENCES

    // Allowed: "system", "light", "dark".
    // Runtime settings can update this property.
    property string themeMode: "dark"

    // Optional visual accessibility mode.
    property bool highContrast: false

    // Set true for touchscreen-oriented layouts.
    property bool touchMode: false

    // Use smaller desktop controls and tighter spacing.
    property bool compactDensity: false

    // User preference: minimize animations.
    property bool reduceMotion: false

    // Intended for constrained devices such as NuraOS.
    property bool lowPowerMode: false

    // Optional UI scaling. Keep within a sensible range.
    property real uiScale: 1.0

    // System theme detection requires Qt 6.5+.
    readonly property bool isDark: themeMode === "dark" || (themeMode === "system" && Qt.styleHints.colorScheme === Qt.Dark)

    readonly property bool isLight: !isDark

    readonly property bool animationsEnabled: !reduceMotion && !lowPowerMode

    // ============================================================
    //  03. BRAND PALETTE
    //  Static colors: do not change with theme.
    // ============================================================

    // YoungLion navy.
    readonly property color navy950: "#0B1020"
    readonly property color navy900: "#111827"
    readonly property color navy850: "#171F32"
    readonly property color navy800: "#1D2940"
    readonly property color navy700: "#2C3C57"
    readonly property color navy600: "#40516D"

    // Primary YoungLion blue.
    readonly property color blue50: "#EEF3FF"
    readonly property color blue100: "#DBE6FF"
    readonly property color blue200: "#BDD0FF"
    readonly property color blue300: "#94B2FF"
    readonly property color blue400: "#638BFA"
    readonly property color blue500: "#345FE8"
    readonly property color blue600: "#294CCD"
    readonly property color blue700: "#203DA8"
    readonly property color blue800: "#1D347F"
    readonly property color blue900: "#192B60"

    // Lion gold. Used sparingly as a secondary accent.
    readonly property color gold50: "#FFF9E9"
    readonly property color gold100: "#FFF0C5"
    readonly property color gold200: "#F8DB8F"
    readonly property color gold300: "#EFC467"
    readonly property color gold400: "#DCA344"
    readonly property color gold500: "#B98122"
    readonly property color gold600: "#936315"
    readonly property color gold700: "#704A10"

    // Neutral palette.
    readonly property color gray0: "#FFFFFF"
    readonly property color gray50: "#F7F9FC"
    readonly property color gray100: "#EFF2F7"
    readonly property color gray200: "#E3E8F0"
    readonly property color gray300: "#CDD5E1"
    readonly property color gray400: "#99A5B8"
    readonly property color gray500: "#718096"
    readonly property color gray600: "#586579"
    readonly property color gray700: "#3E4B60"
    readonly property color gray800: "#273246"
    readonly property color gray900: "#151F30"
    readonly property color gray950: "#0D1422"

    // Static semantic colors.
    readonly property color green500: "#15966E"
    readonly property color green400: "#36C59A"
    readonly property color orange500: "#CF8124"
    readonly property color orange400: "#F1AE55"
    readonly property color red500: "#D74654"
    readonly property color red400: "#F07883"
    readonly property color cyan500: "#138AA8"
    readonly property color cyan400: "#45B9D5"
    readonly property color violet500: "#805DD1"
    readonly property color violet400: "#A790F1"

    // THEME COLORS - BACKGROUNDS

    readonly property color background: isDark ? navy950 : gray50

    readonly property color backgroundSecondary: isDark ? "#0E1626" : gray100

    readonly property color surface: isDark ? navy850 : gray0

    readonly property color surfaceSecondary: isDark ? "#1C273A" : "#F4F6FA"

    readonly property color surfaceTertiary: isDark ? navy800 : gray100

    readonly property color surfaceElevated: isDark ? "#243149" : gray0

    readonly property color surfaceSunken: isDark ? "#090E19" : "#E9EDF4"

    readonly property color surfaceHover: isDark ? "#28364E" : "#EAF0FA"

    readonly property color surfacePressed: isDark ? "#30415D" : "#DDE7FA"

    readonly property color surfaceSelected: isDark ? "#20375D" : blue50

    readonly property color surfaceDisabled: isDark ? "#192233" : gray100

    readonly property color navigationBackground: isDark ? "#10192A" : gray0

    readonly property color toolbarBackground: isDark ? navy950 : gray50

    readonly property color sidebarBackground: isDark ? "#10192A" : "#F2F5FA"

    readonly property color popupBackground: isDark ? navy800 : gray0

    readonly property color dialogBackground: isDark ? navy850 : gray0

    readonly property color inputBackground: isDark ? "#172236" : gray0

    // THEME COLORS - TEXT

    readonly property color textPrimary: highContrast ? (isDark ? "#FFFFFF" : "#000000") : (isDark ? "#F0F4FF" : "#172236")

    readonly property color textSecondary: highContrast ? (isDark ? "#E2E8F0" : "#253246") : (isDark ? "#B5C2D8" : "#526178")

    readonly property color textTertiary: highContrast ? (isDark ? "#D1D9E8" : "#40506B") : (isDark ? "#8596B1" : "#6C7B90")

    readonly property color textDisabled: highContrast ? textSecondary : (isDark ? "#71809A" : "#8794A7")

    readonly property color textInverse: isDark ? navy950 : gray0

    readonly property color textOnPrimary: "#FFFFFF"

    readonly property color textOnSecondary: isDark ? navy950 : "#FFFFFF"

    readonly property color textLink: isDark ? blue300 : blue600

    readonly property color textPlaceholder: isDark ? "#8897AE" : "#8491A5"

    // THEME COLORS - INTERACTION

    property string accent: "blue"
    property bool use24HourClock: true
    property int firstWeekday: 1
    property int nonWorkingDays: 65
    readonly property color primary: accent === "green" ? (isDark ? green400 : "#087052")
        : accent === "violet" ? (isDark ? violet400 : "#6041a7") : (isDark ? blue400 : blue500)

    readonly property color primaryHover: accent === "blue" ? (isDark ? blue300 : blue600) : Qt.lighter(primary, 1.17)

    readonly property color primaryPressed: accent === "blue" ? (isDark ? blue500 : blue700) : Qt.darker(primary, 1.5)

    readonly property color primarySubtle: isDark ? "#1F3152" : blue50

    readonly property color primaryBorder: isDark ? "#496FD1" : blue300

    readonly property color secondary: isDark ? gold300 : gold600

    readonly property color secondaryHover: isDark ? gold200 : gold700

    readonly property color secondarySubtle: isDark ? "#3A2E1B" : gold50

    readonly property color secondaryBorder: isDark ? "#957446" : gold200

    readonly property color selection: isDark ? "#2B4776" : blue100

    readonly property color selectionText: textPrimary

    readonly property color highlight: primary

    readonly property color highlightSubtle: primarySubtle

    // BORDERS, DIVIDERS AND FOCUS

    readonly property color border: highContrast ? (isDark ? "#B6C4DD" : "#35445C") : (isDark ? "#324059" : gray200)

    readonly property color borderSubtle: highContrast ? border : (isDark ? "#283449" : "#EBEFF5")

    readonly property color borderStrong: isDark ? "#667995" : gray400

    readonly property color divider: borderSubtle

    readonly property color focusRing: highContrast ? secondary : primary

    readonly property color focusBackground: primarySubtle

    readonly property int borderWidth: 1
    readonly property int borderWidthStrong: 2
    readonly property int focusRingWidth: 2

    readonly property real disabledOpacity: highContrast ? 0.75 : 0.50

    readonly property real hoverOpacity: 0.08
    readonly property real pressedOpacity: 0.14

    readonly property color modalScrim: isDark ? Qt.rgba(0.0, 0.0, 0.0, 0.72) : Qt.rgba(0.04, 0.07, 0.14, 0.45)

    // SEMANTIC STATUS COLORS

    readonly property color success: isDark ? green400 : green500

    readonly property color successBackground: isDark ? "#11382E" : "#E6F7F0"

    readonly property color successBorder: isDark ? "#256F59" : "#AADFCC"

    readonly property color warning: isDark ? orange400 : orange500

    readonly property color warningBackground: isDark ? "#3A2A18" : "#FFF2DE"

    readonly property color warningBorder: isDark ? "#876137" : "#F3D4A1"

    readonly property color error: isDark ? red400 : red500

    readonly property color errorBackground: isDark ? "#3C1C28" : "#FCECEF"

    readonly property color errorBorder: isDark ? "#874452" : "#F3BBC3"

    readonly property color info: isDark ? cyan400 : cyan500

    readonly property color infoBackground: isDark ? "#123541" : "#E7F6FA"

    readonly property color infoBorder: isDark ? "#34768A" : "#A9DEE8"

    // TYPOGRAPHY

    // Noto Sans is a recommendation, not a bundled font.
    // Qt uses font substitution if it is unavailable.
    readonly property string fontFamily: "Noto Sans"

    // Intended for time values and numeric information.
    readonly property string fontFamilyMono: "monospace"

    readonly property int fontWeightLight: Font.Light
    readonly property int fontWeightNormal: Font.Normal
    readonly property int fontWeightMedium: Font.Medium
    readonly property int fontWeightSemibold: Font.DemiBold
    readonly property int fontWeightBold: Font.Bold

    // Base type scale, in logical pixels.
    readonly property int fontSizeMicro: Math.round(10 * uiScale)
    readonly property int fontSizeTiny: Math.round(11 * uiScale)
    readonly property int fontSizeXs: Math.round(12 * uiScale)
    readonly property int fontSizeSm: Math.round(13 * uiScale)
    readonly property int fontSizeBody: Math.round(14 * uiScale)
    readonly property int fontSizeMd: Math.round(16 * uiScale)
    readonly property int fontSizeLg: Math.round(18 * uiScale)
    readonly property int fontSizeXl: Math.round(20 * uiScale)
    readonly property int fontSize2xl: Math.round(24 * uiScale)
    readonly property int fontSize3xl: Math.round(28 * uiScale)
    readonly property int fontSize4xl: Math.round(34 * uiScale)

    // Semantic typography.
    readonly property int fontSizeAppTitle: fontSizeLg
    readonly property int fontSizePageTitle: fontSize2xl
    readonly property int fontSizeSectionTitle: fontSizeMd
    readonly property int fontSizeDialogTitle: fontSizeXl

    readonly property int fontSizeButton: fontSizeBody
    readonly property int fontSizeInput: fontSizeBody
    readonly property int fontSizeLabel: fontSizeSm
    readonly property int fontSizeCaption: fontSizeXs

    readonly property int fontSizeMonthTitle: fontSize2xl
    readonly property int fontSizeWeekday: fontSizeXs
    readonly property int fontSizeDayNumber: fontSizeBody
    readonly property int fontSizeTodayNumber: fontSizeBody
    readonly property int fontSizeEventTitle: fontSizeXs
    readonly property int fontSizeEventTime: fontSizeTiny

    readonly property real lineHeightTight: 1.15
    readonly property real lineHeightNormal: 1.40
    readonly property real lineHeightRelaxed: 1.60

    readonly property real letterSpacingTight: -0.3
    readonly property real letterSpacingNormal: 0
    readonly property real letterSpacingWide: 0.4

    // SPACING

    readonly property int spacingNone: 0
    readonly property int spacing2xs: Math.round(2 * uiScale)
    readonly property int spacingXs: Math.round(4 * uiScale)
    readonly property int spacingSm: Math.round(8 * uiScale)
    readonly property int spacingMd: Math.round(12 * uiScale)
    readonly property int spacingLg: Math.round(16 * uiScale)
    readonly property int spacingXl: Math.round(20 * uiScale)
    readonly property int spacing2xl: Math.round(24 * uiScale)
    readonly property int spacing3xl: Math.round(32 * uiScale)
    readonly property int spacing4xl: Math.round(40 * uiScale)
    readonly property int spacing5xl: Math.round(48 * uiScale)

    readonly property int pagePadding: compactDensity ? spacingMd : spacingLg

    readonly property int pagePaddingMobile: spacingMd
    readonly property int pagePaddingDesktop: spacing2xl

    readonly property int cardPadding: compactDensity ? spacingMd : spacingLg

    readonly property int dialogPadding: spacing2xl
    readonly property int listItemSpacing: spacingSm
    readonly property int sectionSpacing: spacing2xl

    // CORNER RADII

    readonly property int radiusNone: 0
    readonly property int radius2xs: 2
    readonly property int radiusXs: 4
    readonly property int radiusSm: 6
    readonly property int radiusMd: 10
    readonly property int radiusLg: 14
    readonly property int radiusXl: 18
    readonly property int radius2xl: 24
    readonly property int radius3xl: 32
    readonly property int radiusPill: 999

    readonly property int radiusButton: radiusMd
    readonly property int radiusInput: radiusMd
    readonly property int radiusCard: radiusLg
    readonly property int radiusDialog: radiusXl
    readonly property int radiusPopup: radiusLg
    readonly property int radiusEvent: radiusSm
    readonly property int radiusCalendarCell: radiusMd

    // ICONS AND INTERACTION TARGETS

    readonly property int iconSizeXs: 14
    readonly property int iconSizeSm: 16
    readonly property int iconSizeMd: 20
    readonly property int iconSizeLg: 24
    readonly property int iconSizeXl: 28
    readonly property int iconSize2xl: 32
    readonly property int iconSize3xl: 40

    // Visual icon size and clickable target size are different.
    readonly property int pointerTargetSize: 36
    readonly property int touchTargetSize: 48

    readonly property int minimumHitTarget: touchMode ? touchTargetSize : pointerTargetSize

    readonly property int controlHeightSm: touchMode ? 40 : 30

    readonly property int controlHeightMd: touchMode ? 48 : (compactDensity ? 34 : 40)

    readonly property int controlHeightLg: touchMode ? 56 : 48

    readonly property int buttonHeight: controlHeightMd
    readonly property int inputHeight: controlHeightMd
    readonly property int iconButtonSize: minimumHitTarget

    readonly property int checkboxSize: 20
    readonly property int radioSize: 20
    readonly property int switchWidth: 44
    readonly property int switchHeight: 26

    // RESPONSIVE LAYOUT

    // Breakpoints describe available logical width.
    readonly property int breakpointSmallPhone: 360
    readonly property int breakpointPhone: 600
    readonly property int breakpointTablet: 900
    readonly property int breakpointDesktop: 1200
    readonly property int breakpointWide: 1600

    // Navigation dimensions.
    readonly property int sidebarWidth: compactDensity ? 224 : 256

    readonly property int sidebarMinWidth: 200
    readonly property int sidebarMaxWidth: 320

    readonly property int navigationRailWidth: 68

    readonly property int topBarHeight: touchMode ? 60 : 56

    readonly property int bottomNavigationHeight: 64

    readonly property int desktopTitleBarHeight: 44
    readonly property int desktopToolbarHeight: 48

    readonly property int mobileHeaderHeight: 56

    // Content boundaries.
    readonly property int contentMaxWidth: 1440
    readonly property int formMaxWidth: 560
    readonly property int settingsMaxWidth: 760

    // Right-side event details panel.
    readonly property int detailsPanelWidth: 344
    readonly property int detailsPanelMinWidth: 280

    readonly property int floatingButtonSize: 56
    readonly property int floatingButtonMargin: 20

    // CALENDAR - GENERAL DESIGN

    readonly property color calendarBackground: background
    readonly property color calendarSurface: surface

    readonly property color calendarGridLine: isDark ? "#2A3549" : "#E8ECF3"

    readonly property color calendarGridLineStrong: border

    readonly property color calendarHeaderBackground: surface

    readonly property color calendarHeaderText: textSecondary

    readonly property color calendarWeekdayText: textSecondary

    readonly property color calendarWeekendText: isDark ? "#D6B7C1" : "#89536C"

    readonly property color calendarWeekNumberText: textTertiary

    readonly property color calendarOutsideMonthText: isDark ? "#65748D" : "#9AA6B7"

    readonly property color calendarOutsideMonthBackground: isDark ? "#101827" : "#F8FAFD"

    readonly property color calendarDisabledDayText: textDisabled

    readonly property color calendarDisabledDayBackground: surfaceDisabled

    readonly property color calendarDayHover: surfaceHover

    readonly property color calendarDayPressed: surfacePressed

    readonly property color calendarDaySelected: surfaceSelected

    readonly property color calendarDaySelectedText: textPrimary

    readonly property color calendarDaySelectedBorder: primary

    readonly property color calendarTodayBackground: isDark ? blue400 : blue500

    readonly property color calendarTodayText: "#FFFFFF"

    readonly property color calendarTodayBorder: primary

    readonly property color calendarRangeBackground: isDark ? "#22375A" : "#DFE9FF"

    readonly property color calendarRangeStartBackground: primary

    readonly property color calendarRangeEndBackground: primary

    readonly property color calendarRangeText: textPrimary

    readonly property color calendarHolidayText: isDark ? red400 : red500

    readonly property color calendarHolidayBackground: isDark ? "#351E2B" : "#FFF0F2"

    readonly property color calendarEventOverflowText: textLink

    // CALENDAR - SIZING

    readonly property int monthHeaderHeight: touchMode ? 60 : 52

    readonly property int weekdayHeaderHeight: touchMode ? 40 : 32

    readonly property int monthGridSpacing: 1

    readonly property int calendarDayMinHeight: touchMode ? 44 : 36

    readonly property int calendarDayPreferredHeight: touchMode ? 56 : 48

    readonly property int calendarDayPadding: touchMode ? 6 : 4

    readonly property int dayNumberSize: touchMode ? 34 : 30

    readonly property int todayIndicatorSize: dayNumberSize

    readonly property int eventDotSize: 5
    readonly property int eventDotSpacing: 3

    readonly property int eventBarHeight: touchMode ? 22 : 20

    readonly property int eventBarMinHeight: 18
    readonly property int eventBarPadding: 4
    readonly property int eventBarSpacing: 2

    readonly property int maxVisibleMobileEventDots: 3
    readonly property int maxVisibleDesktopEvents: 4

    // Timeline for Day View and Week View.
    readonly property int timelineHourHeight: compactDensity ? 48 : 64

    readonly property int timelineTimeColumnWidth: 60
    readonly property int timelineMinimumEventHeight: 22

    readonly property color timelineHourLine: calendarGridLine

    readonly property color timelineHalfHourLine: borderSubtle

    readonly property color timelineNowLine: isDark ? red400 : red500

    readonly property color timelineNowDot: timelineNowLine

    readonly property int timelineNowLineWidth: 2
    readonly property int timelineNowDotSize: 8

    readonly property color timelineWorkingHoursBackground: surface

    readonly property color timelineNonWorkingHoursBackground: isDark ? "#121B2B" : "#F5F7FB"

    // All-day event region.
    readonly property int allDayHeaderMinHeight: 40
    readonly property int allDayEventHeight: 24
    readonly property color allDayBackground: surfaceSecondary

    // CALENDAR - EVENT CATEGORY COLORS

    // Solid colors intended for chips, indicators and event bars.

    readonly property color eventDefault: isDark ? blue400 : blue500

    readonly property color eventPersonal: isDark ? violet400 : violet500

    readonly property color eventWork: isDark ? blue400 : blue600

    readonly property color eventStudy: isDark ? cyan400 : cyan500

    readonly property color eventHealth: isDark ? green400 : green500

    readonly property color eventTravel: isDark ? orange400 : orange500

    readonly property color eventFamily: isDark ? "#E78CB7" : "#B74C83"

    readonly property color eventBirthday: isDark ? gold300 : gold600

    readonly property color eventHoliday: isDark ? red400 : red500

    readonly property color eventOther: isDark ? gray400 : gray600

    // Subtle event backgrounds.
    readonly property color eventDefaultBackground: isDark ? "#20345D" : "#EAF0FF"

    readonly property color eventPersonalBackground: isDark ? "#302746" : "#F1EDFD"

    readonly property color eventWorkBackground: isDark ? "#22395E" : "#E7EEFF"

    readonly property color eventStudyBackground: isDark ? "#173D4A" : "#E4F5FA"

    readonly property color eventHealthBackground: isDark ? "#173C32" : "#E4F7EF"

    readonly property color eventTravelBackground: isDark ? "#48321C" : "#FFF1DF"

    readonly property color eventFamilyBackground: isDark ? "#45263A" : "#FBE9F1"

    readonly property color eventBirthdayBackground: isDark ? "#42341F" : "#FFF4D9"

    readonly property color eventHolidayBackground: isDark ? "#45252F" : "#FCECEF"

    readonly property color eventOtherBackground: isDark ? navy800 : gray100

    // Event availability states.
    readonly property color eventBusy: primary
    readonly property color eventFree: success
    readonly property color eventTentative: warning
    readonly property color eventCancelled: textDisabled

    // General event appearance.
    readonly property color eventText: textPrimary

    readonly property color eventSecondaryText: textSecondary

    readonly property color eventSelectedBorder: primary

    readonly property color eventConflictBorder: error

    readonly property real eventCancelledOpacity: 0.50
    readonly property real eventPastOpacity: 0.75

    readonly property int eventBorderWidth: 1
    readonly property int eventAccentBarWidth: 3

    // FORM AND EDITOR

    readonly property int formFieldSpacing: 16
    readonly property int formGroupSpacing: 24

    readonly property int labelBottomSpacing: 6
    readonly property int formSectionHeaderHeight: 32

    readonly property int textFieldMinHeight: controlHeightMd

    readonly property int textAreaMinHeight: 112

    readonly property int formButtonMinWidth: 88

    readonly property int colorPickerSwatchSize: 28
    readonly property int colorPickerSwatchSpacing: 8

    readonly property color inputBorder: border

    readonly property color inputHoverBorder: borderStrong

    readonly property color inputFocusBorder: primary

    readonly property color inputErrorBorder: error

    readonly property color inputDisabledBackground: surfaceDisabled

    readonly property color inputSelectionBackground: selection

    readonly property color inputSelectionText: textPrimary

    // DIALOGS, POPOVERS AND MENUS

    readonly property int dialogMinWidth: 280
    readonly property int dialogPreferredWidth: 440
    readonly property int dialogMaxWidth: 640

    readonly property int popupMinWidth: 200
    readonly property int popupPreferredWidth: 300
    readonly property int popupMaxWidth: 480

    readonly property int menuMinWidth: 180
    readonly property int menuMaxWidth: 320

    readonly property int menuItemHeight: touchMode ? 48 : 36

    readonly property int tooltipMaxWidth: 300

    readonly property int toastMinHeight: 48
    readonly property int toastMaxWidth: 420

    readonly property color tooltipBackground: isDark ? "#374761" : navy850

    readonly property color tooltipText: "#FFFFFF"

    readonly property color toastBackground: isDark ? "#293950" : navy850

    readonly property color toastText: "#FFFFFF"

    // ELEVATION AND LIGHTWEIGHT DEPTH

    // These are only design parameters.
    // They do not create shadows by themselves.
    readonly property int elevationNone: 0
    readonly property int elevationLow: 1
    readonly property int elevationMedium: 2
    readonly property int elevationHigh: 3

    readonly property real shadowOpacityLow: lowPowerMode ? 0 : (isDark ? 0.12 : 0.06)

    readonly property real shadowOpacityMedium: lowPowerMode ? 0 : (isDark ? 0.20 : 0.10)

    readonly property real shadowOpacityHigh: lowPowerMode ? 0 : (isDark ? 0.30 : 0.16)

    readonly property int shadowBlurLow: 6
    readonly property int shadowBlurMedium: 12
    readonly property int shadowBlurHigh: 20

    readonly property int shadowOffsetLow: 2
    readonly property int shadowOffsetMedium: 4
    readonly property int shadowOffsetHigh: 8

    // Prefer borders over shadows on low-end hardware.
    readonly property bool useShadows: !lowPowerMode
    readonly property bool useBlurEffects: false

    // ANIMATION AND MOTION

    // Durations in milliseconds.
    // Zero duration disables optional motion.
    readonly property int durationInstant: 0

    readonly property int durationFast: animationsEnabled ? 100 : 0

    readonly property int durationNormal: animationsEnabled ? 160 : 0

    readonly property int durationSlow: animationsEnabled ? 240 : 0

    readonly property int durationPage: animationsEnabled ? 200 : 0

    readonly property int durationDialog: animationsEnabled ? 180 : 0

    readonly property int durationHover: animationsEnabled ? 90 : 0

    readonly property int durationTheme: animationsEnabled ? 160 : 0

    readonly property int durationMonthChange: animationsEnabled ? 180 : 0

    // Animation distances.
    readonly property int motionDistanceSmall: 4
    readonly property int motionDistanceMedium: 8
    readonly property int motionDistanceLarge: 16

    readonly property real motionScalePressed: 0.98

    readonly property bool animateCalendarNavigation: animationsEnabled

    readonly property bool animatePageTransitions: animationsEnabled

    readonly property bool animateDialogs: animationsEnabled

    // SCROLLING AND GESTURES

    readonly property int scrollBarWidth: touchMode ? 4 : 8

    readonly property int scrollBarMinLength: 24
    readonly property int scrollBarRadius: 4

    readonly property color scrollBarColor: isDark ? "#586983" : "#A6B3C5"

    readonly property color scrollBarHoverColor: isDark ? "#8797AF" : "#7D8CA2"

    readonly property int swipeThreshold: 48
    readonly property int dragThreshold: 8
    readonly property int longPressDuration: 500

    readonly property bool enableOverscrollEffects: !lowPowerMode

    // FEEDBACK AND LOADING STATES

    readonly property int progressBarHeight: 4
    readonly property int progressBarRadius: 2

    readonly property int loadingIndicatorSize: 24
    readonly property int loadingIndicatorLargeSize: 40

    readonly property color progressTrack: surfaceTertiary

    readonly property color progressFill: primary

    readonly property color skeletonBackground: surfaceTertiary

    readonly property color skeletonHighlight: surfaceHover

    readonly property bool animateSkeletons: animationsEnabled

    readonly property int emptyStateIconSize: 56
    readonly property int emptyStateMaxWidth: 360
    readonly property int emptyStateSpacing: 16

    // ACCESSIBILITY

    readonly property int accessibleTouchTarget: 48
    readonly property int minimumReadableFontSize: 12

    readonly property int accessibilityFocusWidth: highContrast ? 3 : 2

    readonly property int accessibilityFocusOffset: 2

    readonly property color accessibilityFocusColor: focusRing

    readonly property bool showKeyboardFocus: true

    // Whether non-essential color differences should also
    // be represented with text, icons or patterns.
    readonly property bool useNonColorStatusIndicators: true

    // LAYERS AND Z ORDER

    readonly property int zBackground: -1
    readonly property int zContent: 0
    readonly property int zFloating: 10
    readonly property int zDropdown: 20
    readonly property int zOverlay: 30
    readonly property int zDialog: 40
    readonly property int zToast: 50
    readonly property int zTooltip: 60

    // DESIGN RULES / FEATURE FLAGS

    // Disable these by default for better performance.
    readonly property bool enableGlassmorphism: false
    readonly property bool enableBackgroundParticles: false
    readonly property bool enableAnimatedGradients: false
    readonly property bool enableHeavyShaders: false

    // UI design capabilities.
    readonly property bool supportsDarkTheme: true
    readonly property bool supportsHighContrast: true
    readonly property bool supportsCompactDensity: true
    readonly property bool supportsTouchLayout: true

    // Prefer a single reusable UI for all supported platforms.
    readonly property bool useAdaptiveLayout: true

    // Reserved for future screenshot / design previews.
    readonly property bool useRoundedCards: true
    readonly property bool useSubtleBorders: true
}
