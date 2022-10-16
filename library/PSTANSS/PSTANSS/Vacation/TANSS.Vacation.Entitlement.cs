using System;
using System.Security;
using System.Xml.Linq;

namespace TANSS {
    namespace Vacation {
        /// <summary>
        ///
        /// </summary>
        [Serializable]
        public class Entitlement {
            #region Properties

            /// <summary>
            ///
            /// </summary>
            public object BaseObject;

            /// <summary>
            ///
            /// </summary>
            public int EmployeeId;

            /// <summary>
            ///
            /// </summary>
            public int Year;

            /// <summary>
            ///
            /// </summary>
            public int NumberOfDays;

            /// <summary>
            ///
            /// </summary>
            public int TransferedDays;

            private string _returnValue;

            #endregion Properties


            #region Statics & Stuff
            /// <summary>
            /// Overrides the default ToString() method
            /// </summary>
            /// <returns></returns>
            public override string ToString () {
                if (!string.IsNullOrEmpty(Convert.ToString(EmployeeId)) && !string.IsNullOrEmpty(Convert.ToString(Year)) && !string.IsNullOrEmpty(Convert.ToString(NumberOfDays)) && !string.IsNullOrEmpty(Convert.ToString(TransferedDays))) {
                    _returnValue = Convert.ToString(Year) + ": EmloyeeId " + Convert.ToString(EmployeeId) + " - " + Convert.ToString(NumberOfDays) + " days";
                } else {
                    _returnValue = this.GetType().Name;
                }

                return _returnValue;
            }
            #endregion Statics & Stuff
        }

    }
}