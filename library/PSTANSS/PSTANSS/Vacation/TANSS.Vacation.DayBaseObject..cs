using System;

namespace TANSS {
    namespace Vacation {
        /// <summary>
        ///
        /// </summary>
        [Serializable]
        public class DayBaseObject {
            #region Properties
                /// <summary>
                ///
                /// </summary>
                public int vacationRequestId;

                /// <summary>
                ///
                /// </summary>
                public int date;

                /// <summary>
                ///
                /// </summary>
                public bool forenoon;

                /// <summary>
                ///
                /// </summary>
                public bool afternoon;

                /// <summary>
                ///
                /// </summary>
                public int startHour;

                /// <summary>
                ///
                /// </summary>
                public int startMinute;

                /// <summary>
                ///
                /// </summary>
                public int endHour;

                /// <summary>
                ///
                /// </summary>
                public int endMinute;

                /// <summary>
                ///
                /// </summary>
                public int pause;

            #endregion Properties
        }
    }
}
