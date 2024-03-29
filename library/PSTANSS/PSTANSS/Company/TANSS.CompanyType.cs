﻿using System;
using System.Security;

namespace TANSS {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class CompanyType {
        #region Properties

        /// <summary>
        ///
        /// </summary>
        public int Id;

        /// <summary>
        ///
        /// </summary>
        public string Name;

        /// <summary>
        ///
        /// </summary>
        public int CategoryId;

        /// <summary>
        ///
        /// </summary>
        public string CategoryName;

        /// <summary>
        ///
        /// </summary>
        public string Icon;

        /// <summary>
        ///
        /// </summary>
        public bool IsHidden;


        private string _returnValue;

        #endregion Properties


        #region Statics & Stuff
        /// <summary>
        /// Overrides the default ToString() method
        /// </summary>
        /// <returns></returns>
        public override string ToString () {
            if (! string.IsNullOrEmpty(Name) ) {
                _returnValue = Name;
            } else {
                _returnValue = this.GetType().Name;
            }

            return _returnValue;
        }
        #endregion Statics & Stuff

    }
}
