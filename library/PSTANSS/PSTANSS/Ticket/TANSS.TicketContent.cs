using System;
using System.Security;

namespace TANSS {
    /// <summary>
    ///
    /// </summary>
    [Serializable]
    public class TicketContent {
        #region Properties

        /// <summary>
        ///
        /// </summary>
        public int TicketId;

        /// <summary>
        ///
        /// </summary>
        public int Id;

        /// <summary>
        ///
        /// </summary>
        public string Type;

        /// <summary>
        ///
        /// </summary>
        public DateTime Date;

        /// <summary>
        ///
        /// </summary>
        public string Text;

        /// <summary>
        ///
        /// </summary>
        public object Object;


        private string _returnValue;

        #endregion Properties


        #region Statics & Stuff
        /// <summary>
        /// Overrides the default ToString() method
        /// </summary>
        /// <returns></returns>
        public override string ToString () {
            _returnValue = "";

            if (!string.IsNullOrEmpty(Convert.ToString(TicketId))) {
                if(string.IsNullOrEmpty(_returnValue)) {
                    _returnValue = "TicketId:" + Convert.ToString(TicketId);
                } else {
                    _returnValue = _returnValue + " TicketId:" + Convert.ToString(TicketId);
                }
            } else if (!string.IsNullOrEmpty(Convert.ToString(Type))) {
                if (string.IsNullOrEmpty(_returnValue)) {
                    _returnValue = Convert.ToString(Type);
                } else {
                    _returnValue = _returnValue + " " + Convert.ToString(Type);
                }
            } else if (!string.IsNullOrEmpty(Convert.ToString(Date))) {
                if (string.IsNullOrEmpty(_returnValue)) {
                    _returnValue = Convert.ToString(Date);
                } else {
                    _returnValue = _returnValue + " Date:" + Date.ToString("yyyy-MM-dd HH:mm:ss");
                }
            } else {
                _returnValue = this.GetType().Name;
            }

            return _returnValue;
        }
        #endregion Statics & Stuff
    }
}
