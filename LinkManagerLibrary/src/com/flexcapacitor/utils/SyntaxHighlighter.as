

/**
 * GeSHi - Generic Syntax Highlighter
 *
 * The GeSHi class for Generic Syntax Highlighting. Please refer to the
 * documentation at http://qbnz.com/highlighter/documentation.php for more
 * information about how to use this class.
 *
 * For changes, release notes, TODOs etc, see the relevant files in the docs/
 * directory.
 *
 *   This file is part of GeSHi.
 *
 *  GeSHi is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  GeSHi is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with GeSHi; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * @package    geshi
 * @subpackage core
 * @author     Nigel McNie <nigel@geshi.org>, Benny Baumann <BenBE@omorphia.de>
 * @copyright  (C) 2004 - 2007 Nigel McNie, (C) 2007 - 2008 Benny Baumann
 * @license    http://gnu.org/copyleft/gpl.html GNU GPL
 *
 */
 
 
/** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * 
 * Converted and Rewritten for AS3
 * 
 * @author Judah Frangipane (when the code works)
 * @author Nicholas Bilyk
 * 
 * https://www.assembla.com/wiki/show/flexcapacitor
 * 
 ** * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

  
 **/


package com.flexcapacitor.utils {
	import com.flexcapacitor.events.HighlightEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	
	import mx.utils.StringUtil;
	
	// dispatches when a language file has been loaded in
	[Event(name="loadComplete", type="com.flexcapacitor.events.HighlightEvent")]
	
	// dispatches when the source has been parsed
	// since the parse method returns the string if the language data is available 
	// this is usually useful when the language file is not known and has to be loaded in first
	[Event(name="complete", type="com.flexcapacitor.events.HighlightEvent")]
	
	public class SyntaxHighlighter extends EventDispatcher {
		
		//
		// GeSHi Constants
		// You should use these constant names in your programs instead of
		// their values - you never know when a value may change in a future
		// version
		//
		
		/** The version of this GeSHi file */
		public static const GESHI_VERSION:String = '1.0.8';
		
		
		//// Define the root directory for the GeSHi code tree
		//if (!defined('GESHI_ROOT')) {
		//    /** The root directory for GeSHi */
		//    define('GESHI_ROOT', dirname(__FILE__) + DIRECTORY_SEPARATOR);
		//}
		///** The language file directory for GeSHi
		//    @access private */
		//define('GESHI_LANG_ROOT', GESHI_ROOT + 'geshi' + DIRECTORY_SEPARATOR);
		
		// Define the root directory for the GeSHi code tree
		/** The root directory for GeSHi */
		public static var GESHI_ROOT:String = "";
		
		// Define the root directory for the GeSHi code tree
		/** The language file directory for GeSHi */
		public static const GESHI_LANG_ROOT:String = GESHI_ROOT + "/geshi/";
		
		// Line numbers - use with enable_line_numbers()
		/** Use no line numbers when building the result */
		public static const GESHI_NO_LINE_NUMBERS:uint = 0;
		/** Use normal line numbers when building the result */
		public static const GESHI_NORMAL_LINE_NUMBERS:uint = 1;
		/** Use fancy line numbers when building the result */
		public static const GESHI_FANCY_LINE_NUMBERS:uint = 2;
		
		// Container HTML type
		/** Use nothing to surround the source */
		public static const GESHI_HEADER_NONE:uint = 0;
		/** Use a "div" to surround the source */
		public static const GESHI_HEADER_DIV:uint = 1;
		/** Use a "pre" to surround the source */
		public static const GESHI_HEADER_PRE:uint = 2;
		/** Use a pre to wrap lines when line numbers are enabled or to wrap the whole code. */
		public static const GESHI_HEADER_PRE_VALID:uint = 3;
		/**
		 * Use a "table" to surround the source:
		 *
		 *  <table>
		 *    <thead><tr><td colspan="2">header</td></tr></thead>
		 *    <tbody><tr><td><pre>linenumbers</pre></td><td><pre>code></pre></td></tr></tbody>
		 *    <tfooter><tr><td colspan="2">footer</td></tr></tfoot>
		 *  </table>
		 *
		 * this is essentially only a workaround for Firefox, see sf#1651996 or take a look at
		 * https://bugzilla.mozilla.org/show_bug.cgi?id=365805
		 * @note when linenumbers are disabled this is essentially the same as GESHI_HEADER_PRE
		 */
		public static const GESHI_HEADER_PRE_TABLE:uint = 4;
		
		// Capitalization constants
		/** Lowercase keywords found */
		public static const GESHI_CAPS_NO_CHANGE:uint = 0;
		/** Uppercase keywords found */
		public static const GESHI_CAPS_UPPER:uint = 1;
		/** Leave keywords found as the case that they are */
		public static const GESHI_CAPS_LOWER:uint = 2;
		
		// Link style constants
		/** Links in the source in the :link state */
		public static const GESHI_LINK:uint = 0;
		/** Links in the source in the :hover state */
		public static const GESHI_HOVER:uint = 1;
		/** Links in the source in the :active state */
		public static const GESHI_ACTIVE:uint = 2;
		/** Links in the source in the :visited state */
		public static const GESHI_VISITED:uint = 3;
		
		// Important string starter/finisher
		// Note that if you change these, they should be as-is: i.e., don't
		// write them as if they had been run through htmlentities()
		/** The starter for important parts of the source */
		public static const GESHI_START_IMPORTANT:String = '<BEGIN GeSHi>';
		/** The ender for important parts of the source */
		public static const GESHI_END_IMPORTANT:String = '<END GeSHi>';
		
		/**#@+
		 *  @access private
		 */
		// When strict mode applies for a language
		/** Strict mode never applies (this is the most common) */
		public static const GESHI_NEVER:uint = 0;
		/** Strict mode *might* apply, and can be enabled or
		    disabled by {@link GeSHi->enable_strict_mode()} */
		public static const GESHI_MAYBE:uint = 1;
		/** Strict mode always applies */
		public static const GESHI_ALWAYS:uint = 2;
		
		// Advanced regexp handling constants, used in language files
		/** The key of the regex array defining what to search for */
		public static const GESHI_SEARCH:uint = 0;
		/** The key of the regex array defining what bracket group in a
		    matched search to use as a replacement */
		public static const GESHI_REPLACE:uint = 1;
		/** The key of the regex array defining any modifiers to the regular expression */
		public static const GESHI_MODIFIERS:uint = 2;
		/** The key of the regex array defining what bracket group in a
		    matched search to put before the replacement */
		public static const GESHI_BEFORE:uint = 3;
		/** The key of the regex array defining what bracket group in a
		    matched search to put after the replacement */
		public static const GESHI_AFTER:uint = 4;
		/** The key of the regex array defining a custom keyword to use
		    for this regexp's html tag class */
		public static const GESHI_CLASS:uint = 5;
		
		/** Used in language files to mark comments */
		public static const GESHI_COMMENTS:uint = 0;
		
		// ATTENTION NICK
		///** Used to work around missing PHP features **/
		//define('GESHI_PHP_PRE_433', !(version_compare(PHP_VERSION, '4.3.3') === 1));
		public static const GESHI_PHP_PRE_433:Boolean = true;
		
		// TODO: DO WE NEED THIS?
		/** make sure we can call stripos **/
		//if (!function_exists('stripos')) {
		//    // the offset param of preg_match is not supported below PHP 4.3.3
		//    if (GESHI_PHP_PRE_433) {
		//        /**
		//         * @ignore
		//         */
		//        function stripos(haystack, needle, offset = null) {
		//            if (!is_null(offset)) {
		//                haystack = substr(haystack, offset);
		//            }
		//            if (preg_match('/'. preg_quote(needle, '/') + '/', haystack, match, PREG_OFFSET_CAPTURE)) {
		//                return match[0][1];
		//            }
		//            return false;
		//        }
		//    }
		//    else {
		//        /**
		//         * @ignore
		//         */
		//        function stripos(haystack, needle, offset = null) {
		//            if (preg_match('/'. preg_quote(needle, '/') + '/', haystack, match, PREG_OFFSET_CAPTURE, offset)) {
		//                return match[0][1];
		//            }
		//            return false;
		//        }
		//    }
		//}
		
		/** some old PHP / PCRE subpatterns only support up to xxx subpatterns in
		    regular expressions. Set this to false if your PCRE lib is up to date
		    @see GeSHi->optimize_regexp_list()
		    TODO: are really the subpatterns the culprit or the overall length of the pattern?
		    **/
		public static const GESHI_MAX_PCRE_SUBPATTERNS:uint = 500;
		
		//Number format specification
		/** Basic number format for integers */
		public static const GESHI_NUMBER_INT_BASIC:uint = 1;        //Default integers \d+
		/** Enhanced number format for integers like seen in C */
		public static const GESHI_NUMBER_INT_CSTYLE:uint = 2;       //Default C-Style \d+[lL]?
		/** Number format to highlight binary numbers with a suffix "b" */
		public static const GESHI_NUMBER_BIN_SUFFIX:uint = 16;           //[01]+[bB]
		/** Number format to highlight binary numbers with a prefix % */
		public static const GESHI_NUMBER_BIN_PREFIX_PERCENT:uint = 32;   //%[01]+
		/** Number format to highlight binary numbers with a prefix 0b (C) */
		public static const GESHI_NUMBER_BIN_PREFIX_0B:uint = 64;        //0b[01]+
		/** Number format to highlight octal numbers with a leading zero */
		public static const GESHI_NUMBER_OCT_PREFIX:uint = 256;           //0[0-7]+
		/** Number format to highlight octal numbers with a suffix of o */
		public static const GESHI_NUMBER_OCT_SUFFIX:uint = 512;           //[0-7]+[oO]
		/** Number format to highlight hex numbers with a prefix 0x */
		public static const GESHI_NUMBER_HEX_PREFIX:uint = 4096;           //0x[0-9a-fA-F]+
		/** Number format to highlight hex numbers with a suffix of h */
		public static const GESHI_NUMBER_HEX_SUFFIX:uint = 8192;           //[0-9][0-9a-fA-F]*h
		/** Number format to highlight floating-point numbers without support for scientific notation */
		public static const GESHI_NUMBER_FLT_NONSCI:uint = 65536;          //\d+\.\d+
		/** Number format to highlight floating-point numbers without support for scientific notation */
		public static const GESHI_NUMBER_FLT_NONSCI_F:uint = 131072;       //\d+(\.\d+)?f
		/** Number format to highlight floating-point numbers with support for scientific notation (E) and optional leading zero */
		public static const GESHI_NUMBER_FLT_SCI_SHORT:uint = 262144;      //\.\d+e\d+
		/** Number format to highlight floating-point numbers with support for scientific notation (E) and required leading digit */
		public static const GESHI_NUMBER_FLT_SCI_ZERO:uint = 524288;       //\d+(\.\d+)?e\d+
		//Custom formats are passed by RX array
		
		// Error detection - use these to analyse faults
		/** No sourcecode to highlight was specified
		 * @deprecated
		 */
		public static const GESHI_ERROR_NO_INPUT:uint = 1;
		/** The language specified does not exist */
		public static const GESHI_ERROR_NO_SUCH_LANG:uint = 2;
		/** GeSHi could not open a file for reading (generally a language file) */
		public static const GESHI_ERROR_FILE_NOT_READABLE:uint = 3;
		/** The header type passed to {@link GeSHi->set_header_type()} was invalid */
		public static const GESHI_ERROR_INVALID_HEADER_TYPE:uint = 4;
		/** The line number type passed to {@link GeSHi->enable_line_numbers()} was invalid */
		public static const GESHI_ERROR_INVALID_LINE_NUMBER_TYPE:uint = 5;
		/**#@-*/


		/*************** LANGUAGE VARIABLES ***************/
		
		/** Default language if none is specified */
		public static var DEFAULT_LANGUAGE:String = ACTIONSCRIPT;
		
		/** Constant for PHP */
		public static const PHP:String = "php";
		
		/** Constant for Actionscript */
		public static const ACTIONSCRIPT:String = "actionscript";
		
		/**
		 * Extension to use for language files. Default is ".json".
		 * 
		 * */
		public static var LANGUAGE_FILE_EXTENSION:String = ".json";
		

		/*************** CLASS VARIABLES ***************/
		
		/**#@+
		 * @access private
		 */
		/**
		 * The source code to highlight
		 * @var string
		 */
		public var source:String = '';
		
		/**
		 * The language to use when highlighting
		 * @var string
		 */
		public var language:String = '';
		
		/**
		 * The data for the language used
		 * @var array
		 */
		public var language_data:Object = new Object();
		
		/**
		 * The path to the language files
		 * @var string
		 */
		public var language_path:String = GESHI_LANG_ROOT;
		
		/**
		 * The error message associated with an error
		 * @var string
		 * @todo check err reporting works
		 */
		public var error:* = false;
		
		/**
		 * Possible error messages
		 * @var array
		 */
		public var error_messages:Object = {
			GESHI_ERROR_NO_SUCH_LANG:'GeSHi could not find the language {LANGUAGE} (using path {PATH})',
			GESHI_ERROR_FILE_NOT_READABLE:'The file specified for load_from_file was not readable',
			GESHI_ERROR_INVALID_HEADER_TYPE:'The header type specified is invalid',
			GESHI_ERROR_INVALID_LINE_NUMBER_TYPE:'The line number type specified is invalid'
		};
		
		/**
		 * Whether highlighting is strict or not
		 * @var boolean
		 */
		public var strict_mode:* = false;
		
		/**
		 * Whether to use CSS classes in output
		 * @var boolean
		 */
		public var use_classes:Boolean = false;
		
		/**
		 * The type of header to use. Can be one of the following
		 * values:
		 *
		 * - GESHI_HEADER_PRE: Source is outputted in a "pre" HTML element.
		 * - GESHI_HEADER_DIV: Source is outputted in a "div" HTML element.
		 * - GESHI_HEADER_NONE: No header is outputted.
		 *
		 * @var int
		 */
		public var header_type:int = GESHI_HEADER_PRE;
		
		/**
		 * Array of permissions for which lexics should be highlighted
		 * @var array
		 */
		public var lexic_permissions:Object = {
			'KEYWORDS':    new Array(),
			'COMMENTS':    {'MULTI': true},
			'REGEXPS':     new Array(),
			'ESCAPE_CHAR': true,
			'BRACKETS':    true,
			'SYMBOLS':     false,
			'STRINGS':     true,
			'NUMBERS':     true,
			'METHODS':     true,
			'SCRIPT':      true
		};
		
		/**
		 * The time it took to parse the code
		 * @var double
		 */
		public var time:uint = 0;
		
		/**
		 * The content of the header block
		 * @var string
		 */
		public var header_content:String = '';
		
		/**
		 * The content of the footer block
		 * @var string
		 */
		public var footer_content:String = '';
		
		/**
		 * The style of the header block
		 * @var string
		 */
		public var header_content_style:String = '';
		
		/**
		 * The style of the footer block
		 * @var string
		 */
		public var footer_content_style:String = '';
		
		/**
		 * Tells if a block around the highlighted source should be forced
		 * if not using line numbering
		 * @var boolean
		 */
		public var force_code_block:Boolean = false;
		
		/**
		 * The styles for hyperlinks in the code
		 * @var array
		 */
		public var link_styles:Array = new Array();
		
		/**
		 * Whether important blocks should be recognised or not
		 * @var boolean
		 * @deprecated
		 * @todo REMOVE THIS FUNCTIONALITY!
		 */
		public var enable_important_blocks:Boolean = false;
		
		/**
		 * Styles for important parts of the code
		 * @var string
		 * @deprecated
		 * @todo As above - rethink the whole idea of important blocks as it is buggy and
		 * will be hard to implement in 1.2
		 */
		public var important_styles:String = 'font-weight: bold; color: red;'; // Styles for important parts of the code
		
		/**
		 * Whether CSS IDs should be added to the code
		 * @var boolean
		 */
		public var add_ids:Boolean = false;
		
		/**
		 * Lines that should be highlighted extra
		 * @var array
		 */
		public var highlight_extra_lines:Array = new Array();
		
		/**
		 * Styles of lines that should be highlighted extra
		 * @var array
		 */
		public var highlight_extra_lines_styles:Array = new Array();
		
		/**
		 * Styles of extra-highlighted lines
		 * @var string
		 */
		public var highlight_extra_lines_style:String = 'background-color: #ffc;';
		
		/**
		 * The line ending
		 * If null, nl2br() will be used on the result string.
		 * Otherwise, all instances of \n will be replaced with line_ending
		 * @var string
		 */
		public var line_ending:String = null;
		
		/**
		 * Number at which line numbers should start at
		 * @var int
		 */
		public var line_numbers_start:int = 1;
		
		/**
		 * The overall style for this code block
		 * @var string
		 */
		public var overall_style:String = 'font-family:monospace;';
		
		/**
		 *  The style for the actual code
		 * @var string
		 */
		public var code_style:String = 'font-family: monospace; font-weight: normal; font-style: normal; margin:0; padding:0; background:inherit;';
		
		/**
		 * The overall class for this code block
		 * @var string
		 */
		public var overall_class:String = '';
		
		/**
		 * The overall ID for this code block
		 * @var string
		 */
		public var overall_id:String = '';
		
		/**
		 * Line number styles
		 * @var string
		 */
		public var line_style1:String = 'font-weight: normal;';
		
		/**
		 * Line number styles for fancy lines
		 * @var string
		 */
		public var line_style2:String = 'font-weight: bold;';
		
		/**
		 * Style for line numbers when GESHI_HEADER_PRE_TABLE is chosen
		 * @var string
		 */
		public var table_linenumber_style:String = 'width:1px;font-weight: normal;text-align:right;margin:0;padding:0 2px;';
		
		/**
		 * Flag for how line numbers are displayed
		 * @var boolean
		 */
		public var line_numbers:int = GESHI_NO_LINE_NUMBERS;
		
		/**
		 * Flag to decide if multi line spans are allowed. Set it to false to make sure
		 * each tag is closed before and reopened after each linefeed.
		 * @var boolean
		 */
		public var allow_multiline_span:Boolean = true;
		
		/**
		 * The "nth" value for fancy line highlighting
		 * @var int
		 */
		public var line_nth_row:int = 0;
		
		/**
		 * The size of tab stops
		 * @var int
		 */
		public var tab_width:int = 8;
		
		/**
		 * Should we use language-defined tab stop widths?
		 * @var int
		 */
		public var use_language_tab_width:Boolean = false;
		
		/**
		 * Default target for keyword links
		 * @var string
		 */
		public var link_target:String = '';
		
		/**
		 * The encoding to use for entity encoding
		 * NOTE: Used with Escape Char Sequences to fix UTF-8 handling (cf. SF#2037598)
		 * @var string
		 */
		public var encoding:String = 'utf-8';
		
		/**
		 * Should keywords be linked?
		 * @var boolean
		 */
		public var keyword_links:Boolean = true;
		
		/**
		 * Currently loaded language file
		 * @var string
		 * @since 1.0.7.22
		 */
		public var loaded_language:* = '';
		
		/**
		 * Length of queue of languages to load
		 * After all items are loaded the loadComplete event is dispatched 
		 * @var string
		 * @since 1.0.7.22
		 */
		public var loaded_language_length:int = 0;
		
		/**
		 * Currently loaded languages cache
		 * @var object
		 * @since 1.0.7.22
		 * AS3 addition
		 */
		public var language_cache:Object = new Object();
		
		/**
		 * Language lookup table
		 * @var object
		 * @since 1.0.7.22
		 * AS3 addition
		 */
		public var language_lookup:Object = {
	                actionscript: ['as'],
	                ada: ['a', 'ada', 'adb', 'ads'],
	                apache: ['conf'],
	                asm: ['ash', 'asm'],
	                asp: ['asp'],
	                bash: ['sh'],
	                c: ['c', 'h'],
	                c_mac: ['c', 'h'],
	                caddcl: [],
	                cadlisp: [],
	                cdfg: ['cdfg'],
	                cobol: ['cbl'],
	                cpp: ['cpp', 'h', 'hpp'],
	                csharp: [],
	                css: ['css'],
	                delphi: ['dpk', 'dpr', 'pp', 'pas'],
	                dos: ['bat', 'cmd'],
	                gettext: ['po', 'pot'],
	                html4strict: ['html', 'htm'],
	                java: ['java'],
	                javascript: ['js'],
	                klonec: ['kl1'],
	                klonecpp: ['klx'],
	                lisp: ['lisp'],
	                lua: ['lua'],
	                mpasm: [],
	                nsis: [],
	                objc: [],
	                oobas: [],
	                oracle8: [],
	                pascal: [],
	                perl: ['pl', 'pm'],
	                php: ['php', 'php5', 'phtml', 'phps'],
	                python: ['py'],
	                qbasic: ['bi'],
	                sas: ['sas'],
	                smarty: [],
	                vb: ['bas'],
	                vbnet: [],
	                visualfoxpro: [],
	                xml: ['xml']
	            };
	            
	    /**
		 * Handles loading a language file
		 *
		 * @since 1.0.8
		 * AS3 Addition
		 */
	    public var request:URLRequest;
		
		/**
		 * Wether the caches needed for parsing are built or not
		 *
		 * @var bool
		 * @since 1.0.8
		 */
		public var parse_cache_built:Boolean = false;
		
		/**
		 * Work around for Suhosin Patch with disabled /e modifier
		 *
		 * Note from suhosins author in config file:
		 * <blockquote>
		 *   The /e modifier inside <code>preg_replace()</code> allows code execution.
		 *   Often it is the cause for remote code execution exploits. It is wise to
		 *   deactivate this feature and test where in the application it is used.
		 *   The developer using the /e modifier should be made aware that he should
		 *   use <code>preg_replace_callback()</code> instead
		 * </blockquote>
		 *
		 * @var array
		 * @since 1.0.8
		 */
		public var _kw_replace_group:int = 0;
		public var _rx_key:int = 0;
		
		/**
		 * some "callback parameters" for handle_multiline_regexps
		 *
		 * @since 1.0.8
		 * @access private
		 * @var string
		 */
		public var _hmr_before:String = '';
		public var _hmr_replace:* = '';
		public var _hmr_after:String = '';
		public var _hmr_key:* = 0;
		
		/**#@-*/
		
		/************************* FUNCTIONS ************************/
	
	    /**
	     * Creates a new GeSHi SyntaxHighlighter object optionally with source and language
	     *
	     * @param string The source code to highlight
	     * @param string The language to highlight the source with
	     * @since 1.0.0
	     */
		public function SyntaxHighlighter(source:String = '', language:String = ''):void {
			
			// set the root directory
			//var url:String = Application(FlexGlobals.topLevelApplication).url;
			//GESHI_ROOT = url.substr(0, url.lastIndexOf("/")) + "/";
			
			if (source!="") {
	            this.source = source;
	        }
	        if (language!="") {
	            this.language = language;
	        }
	        else {
	        	this.language = DEFAULT_LANGUAGE;
	        }
		}
		
		// REVIEW
		/**
		 * Returns an error message associated with the last GeSHi operation,
		 * or false if no error has occured
		 *
		 * @return string|false An error message if there has been an error, else false
		 * @since  1.0.0
		 */
		public function get_error():* {
		    if (error) {
		        //Put some template variables for debugging here ...
		        var debug_tpl_vars:Object = {
		            '{LANGUAGE}': language,
		            '{PATH}': language_path
		        };
		        /* var msg:String = str_replace(
		            array_keys(debug_tpl_vars),
		            array_values(debug_tpl_vars),
		            this.error_messages[this.error]); */
		        var msg:String = error_messages[error] + "<br/>" + debug_tpl_vars.toString();
		
		        return "<br /><strong>GeSHi Error:</strong> "+ msg + " (code {"+error+"})<br />";
		    }
		    return false;
		}
	
	
	    /**
	     * Gets a human-readable language name (thanks to Simon Patterson
	     * for the idea :))
	     *
	     * @return string The name for the current language
	     * @since  1.0.2
	     */
	    public function get_language_name():String {
	        if (GESHI_ERROR_NO_SUCH_LANG == error) {
	            return language_data['LANG_NAME'] + ' (Unknown Language)';
	        }
	        return language_data['LANG_NAME'];
	    }
	
	    /**
	     * Sets the source code for this object
	     *
	     * @param string The source code to highlight
	     * @since 1.0.0
	     */
	    public function set_source(source:String):void {
	        this.source = source;
	        this.highlight_extra_lines = array();
	    }
	
	    /**
	     * Sets the language for this object
	     *
	     * @note since 1.0.8 this function won't reset language-settings by default anymore!
	     *       if you need this set force_reset = true
	     *
	     * @param string The name of the language to use
	     * @since 1.0.0
	     */
	    public function set_language(language:String, force_reset:Boolean = false):void {
	        if (force_reset) {
	            this.loaded_language = false;
	        }
			
	        // Clean up the language name to prevent malicious code injection
	        language = preg_replace('#[^a-zA-Z0-9\-_]#', '', language);
			
	        language = strtolower(language);
			
	        // Retreive the full filename
	        var file_name:String = this.language_path + language + '.php';
	        
	        // add support for cached languages here
	        if (file_name == this.loaded_language) {
	            // this language is already loaded!
	            return;
	        }
			
	        this.language = language;
			
	        this.error = false;
	        this.strict_mode = GESHI_NEVER;
			
	        // Check if we can read the desired file
	        if (!is_readable(file_name)) {
	            this.error = GESHI_ERROR_NO_SUCH_LANG;
	            return;
	        }
			
	        // Load the language for parsing
	        this.load_language(file_name, language);
	    }
	    
	    /**
	     * loads in the languages for this class to work
	     *
	     * @note since 1.0.8 this function won't reset language-settings by default anymore!
	     *       if you need this set force_reset = true
	     *
	     * @param array The names of the languages to load in and cache
	     * @since 1.0.0
	     */
	    public function load_languages(...languages):void {
	       	languages = (languages.length==0) ? new Array(this.language) : languages;
	       	loaded_language_length = 0;
			
			for each (var language:String in languages) {
				
		        // Clean up the language name to prevent malicious code injection
		        language = preg_replace('#[^a-zA-Z0-9\-_]#', '', language);
				
		        language = strtolower(language);
		        
		        if (String(language)=="actionscript") {
		        	language = "actionscript3"; // will this need to be actionscript4 and so on in the future?
		        }
				
		        // Retreive the full filename
		        var file_name:String = this.language_path + language + LANGUAGE_FILE_EXTENSION;
		        
		        // language is already loaded 
		        if (in_array(language, this.language_cache)) {
		        	// we don't need to load it
		        	continue;
		        }
		        loaded_language_length++;
				
				var loader:URLLoader = new URLLoader();
	            configureListeners(loader);
				
	            var request:URLRequest = new URLRequest(file_name);
				
	            try {
	                loader.load(request);
	            } catch (error:Error) {
	                trace("Unable to load requested document " + file_name);
	                loaded_language_length--;
	            }
			
			}
	    }
	
	    /**
	     * Sets the path to the directory containing the language files. Note
	     * that this path is relative to the directory of the script that included
	     * geshi.php, NOT geshi.php itself.
	     *
	     * @param string The path to the language directory
	     * @since 1.0.0
	     * @deprecated The path to the language files should now be automatically
	     *             detected, so this method should no longer be needed. The
	     *             1.1.X branch handles manual setting of the path differently
	     *             so this method will disappear in 1.2.0.
	     */
	    public function set_language_path(path:String):void {
	        if (path) {
	            this.language_path = ('/' == path[strlen(path) - 1]) ? path : path + '/';
	            this.set_language(this.language);        // otherwise set_language_path has no effect
	        }
	    }
	
	    /**
	     * Sets the type of header to be used.
	     *
	     * If GESHI_HEADER_DIV is used, the code is surrounded in a "div".This
	     * means more source code but more control over tab width and line-wrapping.
	     * GESHI_HEADER_PRE means that a "pre" is used - less source, but less
	     * control. Default is GESHI_HEADER_PRE.
	     *
	     * From 1.0.7.2, you can use GESHI_HEADER_NONE to specify that no header code
	     * should be outputted.
	     *
	     * @param int The type of header to be used
	     * @since 1.0.0
	     */
	    public function set_header_type(type:int):void {
	        //Check if we got a valid header type
	        if (!in_array(type, array(GESHI_HEADER_NONE, GESHI_HEADER_DIV,
	            GESHI_HEADER_PRE, GESHI_HEADER_PRE_VALID, GESHI_HEADER_PRE_TABLE))) {
	            this.error = GESHI_ERROR_INVALID_HEADER_TYPE;
	            return;
	        }
	
	        //Set that new header type
	        this.header_type = type;
	    }
	
	    /**
	     * Sets the styles for the code that will be outputted
	     * when this object is parsed. The style should be a
	     * string of valid stylesheet declarations
	     *
	     * @param string  The overall style for the outputted code block
	     * @param boolean Whether to merge the styles with the current styles or not
	     * @since 1.0.0
	     */
	    public function set_overall_style(style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.overall_style = style;
	        } else {
	            this.overall_style += style;
	        }
	    }
	
	    /**
	     * Sets the overall classname for this block of code. This
	     * class can then be used in a stylesheet to style this object's
	     * output
	     *
	     * @param string The class name to use for this block of code
	     * @since 1.0.0
	     */
	    public function set_overall_class(className:String):void {
	        this.overall_class = className;
	    }
	
	    /**
	     * Sets the overall id for this block of code. This id can then
	     * be used in a stylesheet to style this object's output
	     *
	     * @param string The ID to use for this block of code
	     * @since 1.0.0
	     */
	    public function set_overall_id(id:String):void {
	        this.overall_id = id;
	    }
	
	    /**
	     * Sets whether CSS classes should be used to highlight the source. Default
	     * is off, calling this method with no arguments will turn it on
	     *
	     * @param boolean Whether to turn classes on or not
	     * @since 1.0.0
	     */
	    public function enable_classes(flag:Boolean = true):void {
	        this.use_classes = (flag) ? true : false;
	    }
	
	    /**
	     * Sets the style for the actual code. This should be a string
	     * containing valid stylesheet declarations. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * Note: Use this method to override any style changes you made to
	     * the line numbers if you are using line numbers, else the line of
	     * code will have the same style as the line number! Consult the
	     * GeSHi documentation for more information about this.
	     *
	     * @param string  The style to use for actual code
	     * @param boolean Whether to merge the current styles with the new styles
	     * @since 1.0.2
	     */
	    public function set_code_style(style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.code_style = style;
	        } else {
	            this.code_style += style;
	        }
	    }
	
	    /**
	     * Sets the styles for the line numbers.
	     *
	     * @param string The style for the line numbers that are "normal"
	     * @param string|boolean If a string, this is the style of the line
	     *        numbers that are "fancy", otherwise if boolean then this
	     *        defines whether the normal styles should be merged with the
	     *        new normal styles or not
	     * @param boolean If set, is the flag for whether to merge the "fancy"
	     *        styles with the current styles or not
	     * @since 1.0.2
	     */
	    public function set_line_style(style1:String, style2:String = '', preserve_defaults:* = false):void {
	        //Check if we got 2 or three parameters
	        if (is_bool(style2)) {
	            preserve_defaults = style2;
	            style2 = '';
	        }
	
	        //Actually set the new styles
	        if (!preserve_defaults) {
	            this.line_style1 = style1;
	            this.line_style2 = style2;
	        } else {
	            this.line_style1 += style1;
	            this.line_style2 += style2;
	        }
	    }
	
	    /**
	     * Sets whether line numbers should be displayed.
	     *
	     * Valid values for the first parameter are:
	     *
	     *  - GESHI_NO_LINE_NUMBERS: Line numbers will not be displayed
	     *  - GESHI_NORMAL_LINE_NUMBERS: Line numbers will be displayed
	     *  - GESHI_FANCY_LINE_NUMBERS: Fancy line numbers will be displayed
	     *
	     * For fancy line numbers, the second parameter is used to signal which lines
	     * are to be fancy. For example, if the value of this parameter is 5 then every
	     * 5th line will be fancy.
	     *
	     * @param int How line numbers should be displayed
	     * @param int Defines which lines are fancy
	     * @since 1.0.0
	     */
	    public function enable_line_numbers(flag:int, nth_row:int = 5):void {
	        if (GESHI_NO_LINE_NUMBERS != flag && GESHI_NORMAL_LINE_NUMBERS != flag
	            && GESHI_FANCY_LINE_NUMBERS != flag) {
	            this.error = GESHI_ERROR_INVALID_LINE_NUMBER_TYPE;
	        }
	        this.line_numbers = flag;
	        this.line_nth_row = nth_row;
	    }
	
	    /**
	     * Sets wether spans and other HTML markup generated by GeSHi can
	     * span over multiple lines or not. Defaults to true to reduce overhead.
	     * Set it to false if you want to manipulate the output or manually display
	     * the code in an ordered list.
	     *
	     * @param boolean Wether multiline spans are allowed or not
	     * @since 1.0.7.22
	     */
	    public function enable_multiline_span(flag:Boolean):void {
	        this.allow_multiline_span = Boolean(flag);
	    }
	
	    /**
	     * Get current setting for multiline spans, see GeSHi->enable_multiline_span().
	     *
	     * @see enable_multiline_span
	     * @return bool
	     */
	    public function get_multiline_span():Boolean {
	        return this.allow_multiline_span;
	    }
	
	    /**
	     * Sets the style for a keyword group. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * @param int     The key of the keyword group to change the styles of
	     * @param string  The style to make the keywords
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @since 1.0.0
	     */
	    public function set_keyword_group_style(key:int, style:String, preserve_defaults:Boolean = false):void {
	        //Set the style for this keyword group
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['KEYWORDS'][key] = style;
	        } else {
	            this.language_data['STYLES']['KEYWORDS'][key] += style;
	        }
	
	        //Update the lexic permissions
	        if (!isset(this.lexic_permissions['KEYWORDS'][key])) {
	            this.lexic_permissions['KEYWORDS'][key] = true;
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for a keyword group
	     *
	     * @param int     The key of the keyword group to turn on or off
	     * @param boolean Whether to turn highlighting for that group on or off
	     * @since 1.0.0
	     */
	    public function set_keyword_group_highlighting(key:int, flag:Boolean = true):void {
	        this.lexic_permissions['KEYWORDS'][key] = (flag) ? true : false;
	    }
	
	    /**
	     * Sets the styles for comment groups.  If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * @param int     The key of the comment group to change the styles of
	     * @param string  The style to make the comments
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @since 1.0.0
	     */
	    public function set_comments_style(key:int, style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['COMMENTS'][key] = style;
	        } else {
	            this.language_data['STYLES']['COMMENTS'][key] += style;
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for comment groups
	     *
	     * @param int     The key of the comment group to turn on or off
	     * @param boolean Whether to turn highlighting for that group on or off
	     * @since 1.0.0
	     */
	    public function set_comments_highlighting(key:int, flag:Boolean = true):void {
	        this.lexic_permissions['COMMENTS'][key] = (flag) ? true : false;
	    }
	
	    /**
	     * Sets the styles for escaped characters. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * @param string  The style to make the escape characters
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @since 1.0.0
	     */
	    public function set_escape_characters_style(style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['ESCAPE_CHAR'][0] = style;
	        } else {
	            this.language_data['STYLES']['ESCAPE_CHAR'][0] += style;
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for escaped characters
	     *
	     * @param boolean Whether to turn highlighting for escape characters on or off
	     * @since 1.0.0
	     */
	    public function set_escape_characters_highlighting(flag:Boolean = true):void {
	        this.lexic_permissions['ESCAPE_CHAR'] = (flag) ? true : false;
	    }
	
	    /**
	     * Sets the styles for brackets. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * This method is DEPRECATED: use set_symbols_style instead.
	     * This method will be removed in 1.2.X
	     *
	     * @param string  The style to make the brackets
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @since 1.0.0
	     * @deprecated In favour of set_symbols_style
	     */
	    public function set_brackets_style(style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['BRACKETS'][0] = style;
	        } else {
	            this.language_data['STYLES']['BRACKETS'][0] += style;
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for brackets
	     *
	     * This method is DEPRECATED: use set_symbols_highlighting instead.
	     * This method will be remove in 1.2.X
	     *
	     * @param boolean Whether to turn highlighting for brackets on or off
	     * @since 1.0.0
	     * @deprecated In favour of set_symbols_highlighting
	     */
	    public function set_brackets_highlighting(flag:Boolean):void {
	        this.lexic_permissions['BRACKETS'] = (flag) ? true : false;
	    }
	
	    /**
	     * Sets the styles for symbols. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * @param string  The style to make the symbols
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @param int     Tells the group of symbols for which style should be set.
	     * @since 1.0.1
	     */
	    public function set_symbols_style(style:String, preserve_defaults:Boolean = false, group:int = 0):void {
	        // Update the style of symbols
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['SYMBOLS'][group] = style;
	        } else {
	            this.language_data['STYLES']['SYMBOLS'][group] += style;
	        }
	
	        // For backward compatibility
	        if (0 == group) {
	            this.set_brackets_style (style, preserve_defaults);
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for symbols
	     *
	     * @param boolean Whether to turn highlighting for symbols on or off
	     * @since 1.0.0
	     */
	    public function set_symbols_highlighting(flag:Boolean):void {
	        // Update lexic permissions for this symbol group
	        this.lexic_permissions['SYMBOLS'] = (flag) ? true : false;
	
	        // For backward compatibility
	        this.set_brackets_highlighting (flag);
	    }
	
	    /**
	     * Sets the styles for strings. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * @param string  The style to make the escape characters
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @since 1.0.0
	     */
	    public function set_strings_style(style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['STRINGS'][0] = style;
	        } else {
	            this.language_data['STYLES']['STRINGS'][0] += style;
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for strings
	     *
	     * @param boolean Whether to turn highlighting for strings on or off
	     * @since 1.0.0
	     */
	    public function set_strings_highlighting(flag:Boolean):void {
	        this.lexic_permissions['STRINGS'] = (flag) ? true : false;
	    }
	
	    /**
	     * Sets the styles for numbers. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * @param string  The style to make the numbers
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @since 1.0.0
	     */
	    public function set_numbers_style(style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['NUMBERS'][0] = style;
	        } else {
	            this.language_data['STYLES']['NUMBERS'][0] += style;
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for numbers
	     *
	     * @param boolean Whether to turn highlighting for numbers on or off
	     * @since 1.0.0
	     */
	    public function set_numbers_highlighting(flag:Boolean):void {
	        this.lexic_permissions['NUMBERS'] = (flag) ? true : false;
	    }
	
	    /**
	     * Sets the styles for methods. key is a number that references the
	     * appropriate "object splitter" - see the language file for the language
	     * you are highlighting to get this number. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * @param int     The key of the object splitter to change the styles of
	     * @param string  The style to make the methods
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @since 1.0.0
	     */
	    public function set_methods_style(key:int, style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['METHODS'][key] = style;
	        } else {
	            this.language_data['STYLES']['METHODS'][key] += style;
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for methods
	     *
	     * @param boolean Whether to turn highlighting for methods on or off
	     * @since 1.0.0
	     */
	    public function set_methods_highlighting(flag:Boolean):void {
	        this.lexic_permissions['METHODS'] = (flag) ? true : false;
	    }
	
	    /**
	     * Sets the styles for regexps. If preserve_defaults is
	     * true, then styles are merged with the default styles, with the
	     * user defined styles having priority
	     *
	     * @param string  The style to make the regular expression matches
	     * @param boolean Whether to merge the new styles with the old or just
	     *                to overwrite them
	     * @since 1.0.0
	     */
	    public function set_regexps_style(key:int, style:String, preserve_defaults:Boolean = false):void {
	        if (!preserve_defaults) {
	            this.language_data['STYLES']['REGEXPS'][key] = style;
	        } else {
	            this.language_data['STYLES']['REGEXPS'][key] += style;
	        }
	    }
	
	    /**
	     * Turns highlighting on/off for regexps
	     *
	     * @param int     The key of the regular expression group to turn on or off
	     * @param boolean Whether to turn highlighting for the regular expression group on or off
	     * @since 1.0.0
	     */
	    public function set_regexps_highlighting(key:int, flag:Boolean):void {
	        this.lexic_permissions['REGEXPS'][key] = (flag) ? true : false;
	    }
	
	    /**
	     * Sets whether a set of keywords are checked for in a case sensitive manner
	     *
	     * @param int The key of the keyword group to change the case sensitivity of
	     * @param boolean Whether to check in a case sensitive manner or not
	     * @since 1.0.0
	     */
	    public function set_case_sensitivity(key:int, caseSensitive:Boolean):void {
	        this.language_data['CASE_SENSITIVE'][key] = (caseSensitive) ? true : false;
	    }
	
	    /**
	     * Sets the case that keywords should use when found. Use the constants:
	     *
	     *  - GESHI_CAPS_NO_CHANGE: leave keywords as-is
	     *  - GESHI_CAPS_UPPER: convert all keywords to uppercase where found
	     *  - GESHI_CAPS_LOWER: convert all keywords to lowercase where found
	     *
	     * @param int A constant specifying what to do with matched keywords
	     * @since 1.0.1
	     */
	    public function set_case_keywords(caseSensitive:int):void {
	        if (in_array(caseSensitive, array(
	            GESHI_CAPS_NO_CHANGE, GESHI_CAPS_UPPER, GESHI_CAPS_LOWER))) {
	            this.language_data['CASE_KEYWORDS'] = caseSensitive;
	        }
	    }
	
	    /**
	     * Sets how many spaces a tab is substituted for
	     *
	     * Widths below zero are ignored
	     *
	     * @param int The tab width
	     * @since 1.0.0
	     */
	    public function set_tab_width(width:int):void {
	        this.tab_width = intval(width);
	
	        //Check if it fit's the constraints:
	        if (this.tab_width < 1) {
	            //Return it to the default
	            this.tab_width = 8;
	        }
	    }
	
	    /**
	     * Sets whether or not to use tab-stop width specifed by language
	     *
	     * @param boolean Whether to use language-specific tab-stop widths
	     * @since 1.0.7.20
	     */
	    public function set_use_language_tab_width(useTabStop:Boolean):void {
	        this.use_language_tab_width = Boolean(useTabStop);
	    }
	    
	    /****************** FUNCTIONS GET **********************/
	
	    /**
	     * Returns the tab width to use, based on the current language and user
	     * preference
	     *
	     * @return int Tab width
	     * @since 1.0.7.20
	     */
	    public function get_real_tab_width():int {
	        if (!this.use_language_tab_width ||
	            !isset(this.language_data['TAB_WIDTH'])) {
	            return this.tab_width;
	        } else {
	            return this.language_data['TAB_WIDTH'];
	        }
	    }
	
	    /**
	     * Enables/disables strict highlighting. Default is off, calling this
	     * method without parameters will turn it on. See documentation
	     * for more details on strict mode and where to use it.
	     *
	     * @param boolean Whether to enable strict mode or not
	     * @since 1.0.0
	     */
	    public function enable_strict_mode(mode:Boolean = true):void {
	        if (GESHI_MAYBE == this.language_data['STRICT_MODE_APPLIES']) {
	            this.strict_mode = (mode) ? GESHI_ALWAYS : GESHI_NEVER;
	        }
	    }
	
	    /**
	     * Disables all highlighting
	     *
	     * @since 1.0.0
	     * @todo  Rewrite with array traversal
	     * @deprecated In favour of enable_highlighting
	     */
	    public function disable_highlighting():void {
	        this.enable_highlighting(false);
	    }
		
	    /**
	     * Enables all highlighting
	     *
	     * The optional flag parameter was added in version 1.0.7.21 and can be used
	     * to enable (true) or disable (false) all highlighting.
	     *
	     * @since 1.0.0
	     * @param boolean A flag specifying whether to enable or disable all highlighting
	     * @todo  Rewrite with array traversal
	     */
	    public function enable_highlighting(flag:Boolean = true):void {
	        flag = flag ? true : false;
	        
	        
	        /* for each (this.lexic_permissions as key => value) {
	            if (is_array(value)) {
	                for each (value as k => v) {
	                    this.lexic_permissions[key][k] = flag;
	                }
	            } else {
	                this.lexic_permissions[key] = flag;
	            }
	        } */
	        for (var key:* in this.lexic_permissions) {
				var value:* = this.lexic_permissions[key];
	            if (is_array(value)) {
	                for (var k:* in value) {
	                    this.lexic_permissions[key][k] = flag;
	                }
	            } else {
	                this.lexic_permissions[key] = flag;
	            }
			}
	
	        // Context blocks
	        this.enable_important_blocks = flag;
	    }
	
	    /**
	     * Given a file extension, this method returns either a valid geshi language
	     * name, or the empty string if it couldn't be found
	     *
	     * @param string The extension to get a language name for
	     * @param array  A lookup array to use instead of the default one
	     * @since 1.0.5
	     * @todo Re-think about how this method works (maybe make it private and/or make it
	     *       a extension->lang lookup?)
	     * @todo static?
	     */
	    public function get_language_name_from_extension( extension:String, lookup:* = null ):String {
	        if ( !lookup) {
	            lookup = {
	                actionscript: ['as'],
	                ada: ['a', 'ada', 'adb', 'ads'],
	                apache: ['conf'],
	                asm: ['ash', 'asm'],
	                asp: ['asp'],
	                bash: ['sh'],
	                c: ['c', 'h'],
	                c_mac: ['c', 'h'],
	                caddcl: [],
	                cadlisp: [],
	                cdfg: ['cdfg'],
	                cobol: ['cbl'],
	                cpp: ['cpp', 'h', 'hpp'],
	                csharp: [],
	                css: ['css'],
	                delphi: ['dpk', 'dpr', 'pp', 'pas'],
	                dos: ['bat', 'cmd'],
	                gettext: ['po', 'pot'],
	                html4strict: ['html', 'htm'],
	                java: ['java'],
	                javascript: ['js'],
	                klonec: ['kl1'],
	                klonecpp: ['klx'],
	                lisp: ['lisp'],
	                lua: ['lua'],
	                mpasm: [],
	                nsis: [],
	                objc: [],
	                oobas: [],
	                oracle8: [],
	                pascal: [],
	                perl: ['pl', 'pm'],
	                php: ['php', 'php5', 'phtml', 'phps'],
	                python: ['py'],
	                qbasic: ['bi'],
	                sas: ['sas'],
	                smarty: [],
	                vb: ['bas'],
	                vbnet: [],
	                visualfoxpro: [],
	                xml: ['xml']
	            }
	        }
	
	        /* for each (lookup as lang => extensions) {
	            if (in_array(extension, extensions)) {
	                return lang;
	            }
	        } */
	        
	        for (var lang:* in lookup) {
	        	var extensions:* = lookup[lang];
	        	if (in_array(extension, extensions)) {
	        		return lang;
	        	}
	        }
	        return '';
	    }
	
	    /**
	     * Given a file name, this method loads its contents in, and attempts
	     * to set the language automatically. An optional lookup table can be
	     * passed for looking up the language name. If not specified a default
	     * table is used
	     *
	     * The language table is in the form
	     * <pre>array(
	     *   'lang_name' => array('extension', 'extension', ...),
	     *   'lang_name' ...
	     * );</pre>
	     *
	     * @param string The filename to load the source from
	     * @param array  A lookup array to use instead of the default one
	     * @todo Complete rethink of this and above method
	     * @since 1.0.5
	     */
	    public function load_from_file(file_name:String, lookup:* = null):void {
	    	if (lookup==null) lookup = new Array();
	        if (is_readable(file_name)) {
	            this.set_source(file_get_contents(file_name));
	            this.set_language(this.get_language_name_from_extension(substr(strrchr(file_name, '.'), 1), lookup));
	        } else {
	            this.error = GESHI_ERROR_FILE_NOT_READABLE;
	        }
	    }
	
	    /**
	     * Adds a keyword to a keyword group for highlighting
	     *
	     * @param int    The key of the keyword group to add the keyword to
	     * @param string The word to add to the keyword group
	     * @since 1.0.0
	     */
	    public function add_keyword(key:int, word:String):void {
	        if (!in_array(word, this.language_data['KEYWORDS'][key])) {
	            //this.language_data['KEYWORDS'][key][] = word;
	            // don't know what the prev line does NICK!!!!
	            this.language_data['KEYWORDS'][key] = word;
	
	            //NEW in 1.0.8 don't recompile the whole optimized regexp, simply append it
	            if (this.parse_cache_built) {
	                var subkey:int = count(this.language_data['CACHED_KEYWORD_LISTS'][key]) - 1;
	                this.language_data['CACHED_KEYWORD_LISTS'][key][subkey] += '|' + preg_quote(word, '/');
	            }
	        }
	    }
	
	    /**
	     * Removes a keyword from a keyword group
	     *
	     * @param int    The key of the keyword group to remove the keyword from
	     * @param string The word to remove from the keyword group
	     * @param bool   Wether to automatically recompile the optimized regexp list or not.
	     *               Note: if you set this to false and @see GeSHi->parse_code() was already called once,
	     *               for the current language, you have to manually call @see GeSHi->optimize_keyword_group()
	     *               or the removed keyword will stay in cache and still be highlighted! On the other hand
	     *               it might be too expensive to recompile the regexp list for every removal if you want to
	     *               remove a lot of keywords.
	     * @since 1.0.0
	     */
	    public function remove_keyword(key:int, word:String, recompile:Boolean = true):void {
	        var key_to_remove:* = array_search(word, this.language_data['KEYWORDS'][key]);
	        if (key_to_remove !== false) {
	            unset(this.language_data['KEYWORDS'][key][key_to_remove]);
	
	            //NEW in 1.0.8, optionally recompile keyword group
	            if (recompile && this.parse_cache_built) {
	                this.optimize_keyword_group(key);
	            }
	        }
	    }
	
	    /**
	     * Creates a new keyword group
	     *
	     * @param int    The key of the keyword group to create
	     * @param string The styles for the keyword group
	     * @param boolean Whether the keyword group is case sensitive ornot
	     * @param array  The words to use for the keyword group
	     * @since 1.0.0
	     */
	    public function add_keyword_group(key:int, styles:String, case_sensitive:Boolean = true, words:Array = null):void {
	        //words = (array) words;
	        // don't know if this is right NICK!
	        words = (words==null) ? new Array() : words;
	        
	        if  (empty(words)) {
	            // empty word lists mess up highlighting
	            return;
	        }
	
	        // Add the new keyword group internally
	        this.language_data['KEYWORDS'][key] = words;
	        this.lexic_permissions['KEYWORDS'][key] = true;
	        this.language_data['CASE_SENSITIVE'][key] = case_sensitive;
	        this.language_data['STYLES']['KEYWORDS'][key] = styles;
	
	        // NEW in 1.0.8, cache keyword regexp
	        if (this.parse_cache_built) {
	            this.optimize_keyword_group(key);
	        }
	    }
	
	    /**
	     * Removes a keyword group
	     *
	     * @param int    The key of the keyword group to remove
	     * @since 1.0.0
	     */
	    public function remove_keyword_group (key:int):void {
	        // Remove the keyword group internally
	        unset(this.language_data['KEYWORDS'][key]);
	        unset(this.lexic_permissions['KEYWORDS'][key]);
	        unset(this.language_data['CASE_SENSITIVE'][key]);
	        unset(this.language_data['STYLES']['KEYWORDS'][key]);
	
	        // NEW in 1.0.8
	        unset(this.language_data['CACHED_KEYWORD_LISTS'][key]);
	    }
	
	    /**
	     * compile optimized regexp list for keyword group
	     *
	     * @param int   The key of the keyword group to compile & optimize
	     * @since 1.0.8
	     */
	    public function optimize_keyword_group(key:int):void {
	        this.language_data['CACHED_KEYWORD_LISTS'][key] = this.optimize_regexp_list(this.language_data['KEYWORDS'][key]);
	    }
	
	    /**
	     * Sets the content of the header block
	     *
	     * @param string The content of the header block
	     * @since 1.0.2
	     */
	    public function set_header_content(content:String):void {
	        this.header_content = content;
	    }
	
	    /**
	     * Sets the content of the footer block
	     *
	     * @param string The content of the footer block
	     * @since 1.0.2
	     */
	    public function set_footer_content(content:String):void {
	        this.footer_content = content;
	    }
	
	    /**
	     * Sets the style for the header content
	     *
	     * @param string The style for the header content
	     * @since 1.0.2
	     */
	    public function set_header_content_style(style:String):void {
	        this.header_content_style = style;
	    }
	
	    /**
	     * Sets the style for the footer content
	     *
	     * @param string The style for the footer content
	     * @since 1.0.2
	     */
	    public function set_footer_content_style(style:String):void {
	        this.footer_content_style = style;
	    }
	
	    /**
	     * Sets whether to force a surrounding block around
	     * the highlighted code or not
	     *
	     * @param boolean Tells whether to enable or disable this feature
	     * @since 1.0.7.20
	     */
	    public function enable_inner_code_block(flag:Boolean):void {
	        this.force_code_block = flag;
	    }
	
	    /**
	     * Sets the base URL to be used for keywords
	     *
	     * @param int The key of the keyword group to set the URL for
	     * @param string The URL to set for the group. If {FNAME} is in
	     *               the url somewhere, it is replaced by the keyword
	     *               that the URL is being made for
	     * @since 1.0.2
	     */
	    public function set_url_for_keyword_group(group:int, url:String):void {
	        this.language_data['URLS'][group] = url;
	    }
	
	    /**
	     * Sets styles for links in code
	     *
	     * @param int A constant that specifies what state the style is being
	     *            set for - e.g. :hover or :visited
	     * @param string The styles to use for that state
	     * @since 1.0.2
	     */
	    public function set_link_styles(type:int, styles:String):void {
	        this.link_styles[type] = styles;
	    }
	
	    /**
	     * Sets the target for links in code
	     *
	     * @param string The target for links in the code, e.g. _blank
	     * @since 1.0.3
	     */
	    public function set_link_target(target:String):void {
	        if (!target) {
	            this.link_target = '';
	        } else {
	            this.link_target = ' target="' + target + '" ';
	        }
	    }
	
	    /**
	     * Sets styles for important parts of the code
	     *
	     * @param string The styles to use on important parts of the code
	     * @since 1.0.2
	     */
	    public function set_important_styles(styles:String):void {
	        this.important_styles = styles;
	    }
	
	    /**
	     * Sets whether context-important blocks are highlighted
	     *
	     * @param boolean Tells whether to enable or disable highlighting of important blocks
	     * @todo REMOVE THIS SHIZ FROM GESHI!
	     * @deprecated
	     * @since 1.0.2
	     */
	    public function enable_important_blocksSetter(flag:Boolean):void {
	        this.enable_important_blocks = ( flag ) ? true : false;
	    }
	
	    /**
	     * Whether CSS IDs should be added to each line
	     *
	     * @param boolean If true, IDs will be added to each line.
	     * @since 1.0.2
	     */
	    public function enable_ids(flag:Boolean = true):void {
	        this.add_ids = (flag) ? true : false;
	    }
	
	    /**
	     * Specifies which lines to highlight extra
	     *
	     * The extra style parameter was added in 1.0.7.21.
	     *
	     * @param mixed An array of line numbers to highlight, or just a line
	     *              number on its own.
	     * @param string A string specifying the style to use for this line.
	     *              If null is specified, the default style is used.
	     *              If false is specified, the line will be removed from
	     *              special highlighting
	     * @since 1.0.2
	     * @todo  Some data replication here that could be cut down on
	     */
	    public function highlight_lines_extra(lines:*, style:String = null):void {
	        if (is_array(lines)) {
	            // Split up the job using single lines at a time
	            /* for each (lines as line) {
	                this.highlight_lines_extra(line, style);
	            } */
	            for (var line:* in lines) {
	                this.highlight_lines_extra(line, style);
	            }
	        } else {
	            // Mark the line as being highlighted specially
	            lines = intval(lines);
	            this.highlight_extra_lines[lines] = lines;
	
	            // Decide on which style to use
	            if (style === null) { // Check if we should use default style
	                unset(this.highlight_extra_lines_styles[lines]);
	            } else if (style === false) { // Check if to remove this line
	                unset(this.highlight_extra_lines[lines]);
	                unset(this.highlight_extra_lines_styles[lines]);
	            } else {
	                this.highlight_extra_lines_styles[lines] = style;
	            }
	        }
	    }
	
	    /**
	     * Sets the style for extra-highlighted lines
	     *
	     * @param string The style for extra-highlighted lines
	     * @since 1.0.2
	     */
	    public function set_highlight_lines_extra_style(styles:String):void {
	        this.highlight_extra_lines_style = styles;
	    }
	
	    /**
	     * Sets the line-ending
	     *
	     * @param string The new line-ending
	     * @since 1.0.2
	     */
	    public function set_line_ending(line_ending:String):void {
	        this.line_ending = line_ending;
	    }
	
	    /**
	     * Sets what number line numbers should start at. Should
	     * be a positive integer, and will be converted to one.
	     *
	     * <b>Warning:</b> Using this method will add the "start"
	     * attribute to the &lt;ol&gt; that is used for line numbering.
	     * This is <b>not</b> valid XHTML strict, so if that's what you
	     * care about then don't use this method. Firefox is getting
	     * support for the CSS method of doing this in 1.1 and Opera
	     * has support for the CSS method, but (of course) IE doesn't
	     * so it's not worth doing it the CSS way yet.
	     *
	     * @param int The number to start line numbers at
	     * @since 1.0.2
	     */
	    public function start_line_numbers_at(number:int):void {
	        this.line_numbers_start = abs(intval(number));
	    }
	
	    /**
	     * Sets the encoding used for htmlspecialchars(), for international
	     * support.
	     *
	     * NOTE: This is not needed for now because htmlspecialchars() is not
	     * being used (it has a security hole in PHP4 that has not been patched).
	     * Maybe in a future version it may make a return for speed reasons, but
	     * I doubt it.
	     *
	     * @param string The encoding to use for the source
	     * @since 1.0.3
	     */
	    public function set_encoding(encoding:String):void {
	        if (encoding) {
	          this.encoding = strtolower(encoding);
	        }
	    }
	
	    /**
	     * Turns linking of keywords on or off.
	     *
	     * @param boolean If true, links will be added to keywords
	     * @since 1.0.2
	     */
	    public function enable_keyword_links(enable:Boolean = true):void {
	        this.keyword_links = enable;
	    }
	
	    /**
	     * Setup caches needed for styling. This is automatically called in
	     * parse_code() and get_stylesheet() when appropriate. This function helps
	     * stylesheet generators as they rely on some style information being
	     * preprocessed
	     *
	     * @since 1.0.8
	     * @access private
	     */
	    public function build_style_cache():void {
	        //Build the style cache needed to highlight numbers appropriate
	        if(this.lexic_permissions['NUMBERS']) {
	            //First check what way highlighting information for numbers are given
	            if(!isset(this.language_data['NUMBERS'])) {
	                this.language_data['NUMBERS'] = 0;
	            }
	
	            if(is_array(this.language_data['NUMBERS'])) {
	                this.language_data['NUMBERS_CACHE'] = this.language_data['NUMBERS'];
	            } else {
	                this.language_data['NUMBERS_CACHE'] = array();
	                if(!this.language_data['NUMBERS']) {
	                    this.language_data['NUMBERS'] =
	                        GESHI_NUMBER_INT_BASIC |
	                        GESHI_NUMBER_FLT_NONSCI;
	                }
					
					var i:uint = 0
	                for(var j:uint = this.language_data['NUMBERS']; j > 0; ++i, j>>=1) {
	                    //Rearrange style indices if required ...
	                    //if(isset(this.language_data['STYLES']['NUMBERS'][1<<i])) {
	                    if(isset_drilldown(this.language_data,'STYLES','NUMBERS',1<<i)) {
	                        this.language_data['STYLES']['NUMBERS'][i] =
	                            this.language_data['STYLES']['NUMBERS'][1<<i];
	                        unset(this.language_data['STYLES']['NUMBERS'][1<<i]);
	                    }
	
	                    //Check if this bit is set for highlighting
	                    if(j&1) {
	                        //So this bit is set ...
	                        //Check if it belongs to group 0 or the actual stylegroup
	                        //if(isset(this.language_data['STYLES']['NUMBERS'][i])) {
	                        if(isset_drilldown(this.language_data,'STYLES','NUMBERS',i)) {
	                            this.language_data['NUMBERS_CACHE'][i] = 1 << i;
	                        } else {
	                            //if(!isset(this.language_data['NUMBERS_CACHE'][0])) {
	                            if(!isset_drilldown(this.language_data,'NUMBERS_CACHE',0)) {
	                                this.language_data['NUMBERS_CACHE'][0] = 0;
	                            }
	                            this.language_data['NUMBERS_CACHE'][0] |= 1 << i;
	                        }
	                    }
	                }
	            }
	        }
	    }
	
	    /**
	     * Setup caches needed for parsing. This is automatically called in parse_code() when appropriate.
	     * This function makes stylesheet generators much faster as they do not need these caches.
	     *
	     * @since 1.0.8
	     * @access private
	     */
	    public function build_parse_cache():void {
	        // cache symbol regexp
	        //As this is a costy operation, we avoid doing it for multiple groups ...
	        //Instead we perform it for all symbols at once.
	        //
	        //For this to work, we need to reorganize the data arrays.
	        if (this.lexic_permissions['SYMBOLS'] && !empty(this.language_data['SYMBOLS'])) {
	            this.language_data['MULTIPLE_SYMBOL_GROUPS'] = count(this.language_data['STYLES']['SYMBOLS']) > 1;
	
	            this.language_data['SYMBOL_DATA'] = array();
	            var symbol_preg_multi:* = array(); // multi char symbols
	            var symbol_preg_single:* = array(); // single char symbols
	            for (var key:* in this.language_data['SYMBOLS']) {
	            	var symbols:* = this.language_data['SYMBOLS'][key];
	            	
	                if (is_array(symbols)) {
	                    //for each (symbols as sym) {
	                    for (var sym:* in symbols) {
	                        sym = this.hsc(sym);
	                        if (!isset(this.language_data['SYMBOL_DATA'][sym])) {
	                            this.language_data['SYMBOL_DATA'][sym] = key;
	                            if (isset(sym[1])) { // multiple chars
	                                symbol_preg_multi = preg_quote(sym, '/');
	                            } else { // single char
	                                if (sym == '-') {
	                                    // don't trigger range out of order error
	                                    symbol_preg_single = '\-';
	                                } else {
	                                    symbol_preg_single = preg_quote(sym, '/');
	                                }
	                            }
	                        }
	                    }
	                } else {
	                    symbols = this.hsc(symbols);
	                    if (!isset(this.language_data['SYMBOL_DATA'][symbols])) {
	                        this.language_data['SYMBOL_DATA'][symbols] = 0;
	                        if (isset(symbols[1])) { // multiple chars
	                            symbol_preg_multi = preg_quote(symbols, '/');
	                        } else if (symbols == '-') {
	                            // don't trigger range out of order error
	                            symbol_preg_single = '\-';
	                        } else { // single char
	                            symbol_preg_single = preg_quote(symbols, '/');
	                        }
	                    }
	                }
	            }
	
	            //Now we have an array with each possible symbol as the key and the style as the actual data.
	            //This way we can set the correct style just the moment we highlight ...
	            //
	            //Now we need to rewrite our array to get a search string that
	            var symbol_preg:* = array();
	            if (!empty(symbol_preg_single)) {
	                symbol_preg = '[' + implode('', symbol_preg_single) + ']';
	            }
	            if (!empty(symbol_preg_multi)) {
	                symbol_preg = implode('|', symbol_preg_multi);
	            }
	            this.language_data['SYMBOL_SEARCH'] = implode("|", symbol_preg);
	        }
	
	        // cache optimized regexp for keyword matching
	        // remove old cache
	        this.language_data['CACHED_KEYWORD_LISTS'] = array();
	        
	        //for each (array_keys(this.language_data['KEYWORDS']) as key) {
	        for (key in array_keys(this.language_data['KEYWORDS'])) {
	            if (!isset(this.lexic_permissions['KEYWORDS'][key]) ||
	                    this.lexic_permissions['KEYWORDS'][key]) {
	                this.optimize_keyword_group(key);
	            }
	        }
	
	        // brackets
	        if (this.lexic_permissions['BRACKETS']) {
	            this.language_data['CACHE_BRACKET_MATCH'] = array('[', ']', '(', ')', '{', '}');
	            
	            if (!this.use_classes && isset_drilldown(this.language_data,'STYLES','BRACKETS',0)) {
	                this.language_data['CACHE_BRACKET_REPLACE'] = array(
	                    '<| style="' + this.language_data['STYLES']['BRACKETS'][0] + '">&#91;|>',
	                    '<| style="' + this.language_data['STYLES']['BRACKETS'][0] + '">&#93;|>',
	                    '<| style="' + this.language_data['STYLES']['BRACKETS'][0] + '">&#40;|>',
	                    '<| style="' + this.language_data['STYLES']['BRACKETS'][0] + '">&#41;|>',
	                    '<| style="' + this.language_data['STYLES']['BRACKETS'][0] + '">&#123;|>',
	                    '<| style="' + this.language_data['STYLES']['BRACKETS'][0] + '">&#125;|>'
	                );
	            }
	            else {
	                this.language_data['CACHE_BRACKET_REPLACE'] = array(
	                    '<| class="br0">&#91;|>',
	                    '<| class="br0">&#93;|>',
	                    '<| class="br0">&#40;|>',
	                    '<| class="br0">&#41;|>',
	                    '<| class="br0">&#123;|>',
	                    '<| class="br0">&#125;|>'
	                );
	            }
	        }
	
	        //Build the parse cache needed to highlight numbers appropriate
	        if(this.lexic_permissions['NUMBERS']) {
	            //Check if the style rearrangements have been processed ...
	            //This also does some preprocessing to check which style groups are useable ...
	            if(!isset(this.language_data['NUMBERS_CACHE'])) {
	                this.build_style_cache();
	            }
	
	            //Number format specification
	            //All this formats are matched case-insensitively!
	            var numbers_format:Object = {};
	            numbers_format[GESHI_NUMBER_INT_BASIC] = '(?<![0-9a-z_\.%])(?<![\d\.]e[+\-])[1-9]\d*?(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_INT_CSTYLE] = '(?<![0-9a-z_\.%])(?<![\d\.]e[+\-])[1-9]\d*?l(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_BIN_SUFFIX] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])[01]+?b(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_BIN_PREFIX_PERCENT] = '(?<![0-9a-z_\.%])(?<![\d\.]e[+\-])%[01]+?(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_BIN_PREFIX_0B] = '(?<![0-9a-z_\.%])(?<![\d\.]e[+\-])0b[01]+?(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_OCT_PREFIX] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])0[0-7]+?(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_OCT_SUFFIX] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])[0-7]+?o(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_HEX_PREFIX] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])0x[0-9a-f]+?(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_HEX_SUFFIX] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])\d[0-9a-f]*?h(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_FLT_NONSCI] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])\d+?\.\d+?(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_FLT_NONSCI_F] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])(?:\d+?(?:\.\d*?)?|\.\d+?)f(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_FLT_SCI_SHORT] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])\.\d+?(?:e[+\-]?\d+?)?(?![0-9a-z\.])';
	            numbers_format[GESHI_NUMBER_FLT_SCI_ZERO] = '(?<![0-9a-z_\.])(?<![\d\.]e[+\-])(?:\d+?(?:\.\d*?)?|\.\d+?)(?:e[+\-]?\d+?)?(?![0-9a-z\.])';
	
	            //At this step we have an associative array with flag groups for a
	            //specific style or an string denoting a regexp given its index.
	            this.language_data['NUMBERS_RXCACHE'] = array();
	            //for each(this.language_data['NUMBERS_CACHE'] as key => rxdata) {
	            for (key in this.language_data['NUMBERS_CACHE']) {
	            	var rxdata:* = this.language_data['NUMBERS_CACHE'][key];
	            	var regexp:*;
	                if(is_string(rxdata)) {
	                    regexp = rxdata;
	                } else {
	                    //This is a bitfield of number flags to highlight:
	                    //Build an array, implode them together and make this the actual RX
	                    var rxuse:* = array();
	                    for(var i:int = 1; i <= rxdata; i<<=1) {
	                        if(rxdata & i) {
	                            rxuse = numbers_format[i];
	                        }
	                    }
	                    regexp = implode("|", rxuse);
	                }
	
	                this.language_data['NUMBERS_RXCACHE'][key] = "/(?<!<\|\/NUM!)(?<!\d\/>)(regexp)(?!\|>)/i";
	            }
	        }
	
	        this.parse_cache_built = true;
	    }
	
	    /**
	     * Returns the code in this.source, highlighted and surrounded by the
	     * nessecary HTML.
	     *
	     * This should only be called ONCE, cos it's SLOW! If you want to highlight
	     * the same source multiple times, you're better off doing a whole lot of
	     * str_replaces to replace the &lt;span&gt;s
	     *
	     * @since 1.0.0
	     */
	    public function parse_code ():String {
	        // Start the timer
	        var start_time:uint = microtime();
	        
	        // break out of 3 conditions
	        var break3:Boolean = false;
	        
	        // random variable not found anywhere else:
	        var matches_rx:*;
	
	        // Firstly, if there is an error, we won't highlight
	        if (this.error) {
	            //Escape the source for output
	            var result:String = this.hsc(this.source);
	
	            //This fix is related to SF#1923020, but has to be applied regardless of
	            //actually highlighting symbols.
	            result = str_replace(array('<SEMI>', '<PIPE>'), array(';', '|'), result);
	
	            // Timing is irrelevant
	            this.set_time(start_time, start_time);
	            this.finalise(result);
	            return result;
	        }
	
	        // make sure the parse cache is up2date
	        if (!this.parse_cache_built) {
	            this.build_parse_cache();
	        }
	
	        // Replace all newlines to a common form.
	        var code:String = str_replace("\r\n", "\n", this.source);
	        code = str_replace("\r", "\n", code);
	
	        // Add spaces for regular expression matching and line numbers
			//        code = "\n" + code + "\n";
	
	        // Initialise various stuff
	        var length:int           = strlen(code);
	        var COMMENT_MATCHED:Boolean  = false;
	        var stuff_to_parse:String   = '';
	        var endresult:String        = '';
	
	        // "Important" selections are handled like multiline comments
	        // @todo GET RID OF THIS SHIZ
	        if (this.enable_important_blocks) {
	            this.language_data['COMMENT_MULTI'][GESHI_START_IMPORTANT] = GESHI_END_IMPORTANT;
	        }
	
	        if (this.strict_mode) {
	            // Break the source into bits. Each bit will be a portion of the code
	            // within script delimiters - for example, HTML between < and >
	            var k:int = 0;
	            var parts:* = array();
	            var matches:* = array();
	            var next_match_pointer:* = null;
	            // we use a copy to unset delimiters on demand (when they are not found)
	            var delim_copy:* = this.language_data['SCRIPT_DELIMITERS'];
	            var i:int = 0;
	            while (i < length) {
	                var next_match_pos:* = length + 1; // never true
	                
	                //for each (delim_copy as dk => delimiters) {
	                for (var dk:String in delim_copy) {
	                	var delimiters:* = delim_copy[dk];
	                	
	                    if(is_array(delimiters)) {
	                        //for each (delimiters as open => close) {
	                        for (var open:String in delimiters) {
	                        	var close:* = delimiters[open];
	                        	
	                            // make sure the cache is setup properly
	                            if (!isset(matches[dk][open])) {
	                                matches[dk][open] = {
	                                    'next_match': -1,
	                                    'dk': dk,
	
	                                    'open': open, // needed for grouping of adjacent code blocks (see below)
	                                    'open_strlen': strlen(open),
	
	                                    'close': close,
	                                    'close_strlen': strlen(close)
	                                };
	                            }
	                            // Get the next little bit for this opening string
	                            if (matches[dk][open]['next_match'] < i) {
	                                // only find the next pos if it was not already cached
	                                var open_pos:* = strpos(code, open, i);
	                                if (open_pos === false) {
	                                    // no match for this delimiter ever
	                                    unset(delim_copy[dk][open]);
	                                    continue;
	                                }
	                                matches[dk][open]['next_match'] = open_pos;
	                            }
	                            if (matches[dk][open]['next_match'] < next_match_pos) {
	                                //So we got a new match, update the close_pos
	                                matches[dk][open]['close_pos'] =
	                                    strpos(code, close, matches[dk][open]['next_match']+1);
	
	                                //next_match_pointer =& matches[dk][open];
	                                next_match_pointer = next_match_pointer && matches[dk][open];
	                                next_match_pos = matches[dk][open]['next_match'];
	                            }
	                        }
	                    } else {
	                        //So we should match an RegExp as Strict Block ...
	                        /**
	                         * The value in delimiters is expected to be an RegExp
	                         * containing exactly 2 matching groups:
	                         *  - Group 1 is the opener
	                         *  - Group 2 is the closer
	                         */
	                        if(!GESHI_PHP_PRE_433 && //Needs proper rewrite to work with PHP >=4.3.0; 4.3.3 is guaranteed to work.
	                            preg_match(delimiters, code, matches_rx, PREG_OFFSET_CAPTURE, i)) {
	                            //We got a match ...
	                            matches[dk] = {
	                                'next_match': matches_rx[1][1],
	                                'dk': dk,
	
	                                'close_strlen': strlen(matches_rx[2][0]),
	                                'close_pos': matches_rx[2][1]
	                            };
	                        } else {
	                            // no match for this delimiter ever
	                            unset(delim_copy[dk]);
	                            continue;
	                        }
	
	                        if (matches[dk]['next_match'] <= next_match_pos) {
	                            //next_match_pointer =& matches[dk];
	                            next_match_pointer = next_match_pointer && matches[dk];
	                            next_match_pos = matches[dk]['next_match'];
	                        }
	                    }
	                }
	                // non-highlightable text
	                parts[k] = {
	                    1: substr(code, i, next_match_pos - i)
	                };
	                ++k;
	
	                if (next_match_pos > length) {
	                    // out of bounds means no next match was found
	                    break;
	                }
	
	                // highlightable code
	                parts[k][0] = next_match_pointer['dk'];
	
	                //Only combine for non-rx script blocks
	                if(is_array(delim_copy[next_match_pointer['dk']])) {
	                    // group adjacent script blocks, e.g. <foobar><asdf> should be one block, not three!
	                    i = next_match_pos + next_match_pointer['open_strlen'];
	                    while (true) {
	                        var close_pos:* = strpos(code, next_match_pointer['close'], i);
	                        if (close_pos == false) {
	                            break;
	                        }
	                        i = close_pos + next_match_pointer['close_strlen'];
	                        if (i == length) {
	                            break;
	                        }
	                        if (code[i] == next_match_pointer['open'][0] && (next_match_pointer['open_strlen'] == 1 ||
	                            substr(code, i, next_match_pointer['open_strlen']) == next_match_pointer['open'])) {
	                            // merge adjacent but make sure we don't merge things like <tag><!-- comment -->
	                            //for each (matches as submatches) {
	                            for (var submatches:* in matches) {
	                            	
	                                //for each (submatches as match) {
	                                for (var match:* in submatches) {
	                                    if (match['next_match'] == i) {
	                                        // a different block already matches here!
	                                        //break 3;
	                                        break3 = true;
	                                        if (break3) break;
	                                    }
	                                }
	                                if (break3) break;
	                                
	                            }
	                            if (break3) {
	                            	break3 = false;
	                            	break;
	                            }
	                            
	                        } else {
	                            break;
	                        }
	                    }
	                } else {
	                    close_pos = next_match_pointer['close_pos'] + next_match_pointer['close_strlen'];
	                    i = close_pos;
	                }
	
	                if (close_pos === false) {
	                    // no closing delimiter found!
	                    parts[k][1] = substr(code, next_match_pos);
	                    ++k;
	                    break;
	                } else {
	                    parts[k][1] = substr(code, next_match_pos, i - next_match_pos);
	                    ++k;
	                }
	            }
	            unset(delim_copy, next_match_pointer, next_match_pos, matches);
	            var num_parts:* = k;
	
	            if (num_parts == 1 && this.strict_mode == GESHI_MAYBE) {
	                // when we have only one part, we don't have anything to highlight at all.
	                // if we have a "maybe" strict language, this should be handled as highlightable code
	                /* parts = array(
	                    0 => array(
	                        0 => '',
	                        1 => ''
	                    ),
	                    1 => array(
	                        0 => null,
	                        1 => parts[0][1]
	                    )
	                ); */
	                parts = {
	                    0: {
	                        0: '',
	                        1: ''
	                    },
	                    1: {
	                        0: null,
	                        1: parts[0][1]
	                    }
	                };
	                num_parts = 2;
	            }
	
	        } else {
	            // Not strict mode - simply dump the source into
	            // the array at index 1 (the first highlightable block)
	            parts = {
	                0: {
	                    0: '',
	                    1: ''
	                },
	                1: {
	                    0: null,
	                    1: code
	                }
	            };
	            num_parts = 2;
	        }
	
	        //Unset variables we won't need any longer
	        unset(code);
	
	        //Preload some repeatedly used values regarding hardquotes ...
	        var hq:* = isset(this.language_data['HARDQUOTE']) ? this.language_data['HARDQUOTE'][0] : false;
	        var hq_strlen:* = strlen(hq);
	
	        //Preload if line numbers are to be generated afterwards
	        //Added a check if line breaks should be forced even without line numbers, fixes SF#1727398
	        var check_linenumbers:* = this.line_numbers != GESHI_NO_LINE_NUMBERS ||
	            !empty(this.highlight_extra_lines) || !this.allow_multiline_span;
	
	        //preload the escape char for faster checking ...
	        var escaped_escape_char:* = this.hsc(this.language_data['ESCAPE_CHAR']);
	        
	        // this is used for single-line comments
	        var sc_disallowed_before:* = "";
	        var sc_disallowed_after:* = "";
	
	        if (isset(this.language_data['PARSER_CONTROL'])) {
	            if (isset(this.language_data['PARSER_CONTROL']['COMMENTS'])) {
	                if (isset(this.language_data['PARSER_CONTROL']['COMMENTS']['DISALLOWED_BEFORE'])) {
	                    sc_disallowed_before = this.language_data['PARSER_CONTROL']['COMMENTS']['DISALLOWED_BEFORE'];
	                }
	                if (isset(this.language_data['PARSER_CONTROL']['COMMENTS']['DISALLOWED_AFTER'])) {
	                    sc_disallowed_after = this.language_data['PARSER_CONTROL']['COMMENTS']['DISALLOWED_AFTER'];
	                }
	            }
	        }
	
	        //Fix for SF#1932083: Multichar Quotemarks unsupported
	        var is_string_starter:* = arrayObject();
	        if (this.lexic_permissions['STRINGS']) {
	            //for each (this.language_data['QUOTEMARKS'] as quotemark) {
	            for (var quotemark:* in this.language_data['QUOTEMARKS']) {
	            	if (Object(quotemark).hasOwnProperty("0")) {
		                if (!isset(is_string_starter[quotemark[0]])) {
		                    is_string_starter[quotemark[0]] = String(quotemark);
		                } else if (is_string(is_string_starter[quotemark[0]])) {
		                    is_string_starter[quotemark[0]] = new Array(
		                        is_string_starter[quotemark[0]],
		                        quotemark);
		                } else {
		                    is_string_starter[quotemark[0]] = quotemark;
		                }
	             	}
	            }
	        }
	
	        // Now we go through each part. We know that even-indexed parts are
	        // code that shouldn't be highlighted, and odd-indexed parts should
	        // be highlighted
	        for (var key:* = 0; key < num_parts; ++key) {
	            var STRICTATTRS:* = '';
	
	            // If this block should be highlighted...
	            if (!(key & 1)) {
	                // Else not a block to highlight
	                endresult += this.hsc(parts[key][1]);
	                unset(parts[key]);
	                continue;
	            }
	
	            result = '';
	            var part:* = parts[key][1];
	
	            var highlight_part:* = true;
	            if (this.strict_mode && !is_null(parts[key][0])) {
	                // get the class key for this block of code
	                var script_key:* = parts[key][0];
	                highlight_part = this.language_data['HIGHLIGHT_STRICT_BLOCK'][script_key];
	                if (this.language_data['STYLES']['SCRIPT'][script_key] != '' &&
	                    this.lexic_permissions['SCRIPT']) {
	                    var attributes:*;
	                    // Add a span element around the source to
	                    // highlight the overall source block
	                    if (!this.use_classes &&
	                        this.language_data['STYLES']['SCRIPT'][script_key] != '') {
	                        attributes = ' style="' + this.language_data['STYLES']['SCRIPT'][script_key] + '"';
	                    } else {
	                        attributes = ' class="sc' + script_key + '"';
	                    }
	                    result += "<spanattributes>";
	                    STRICTATTRS = attributes;
	                }
	            }
	
	            if (highlight_part) {
	                // Now, highlight the code in this block. This code
	                // is really the engine of GeSHi (along with the method
	                // parse_non_string_part).
	
	                // cache comment regexps incrementally
	                var comment_regexp_cache:* = array();
	                var next_comment_regexp_pos:* = -1;
	                var next_comment_multi_pos:* = -1;
	                var next_comment_single_pos:* = -1;
	                var comment_regexp_cache_per_key:* = array();
	                var comment_multi_cache_per_key:* = array();
	                var comment_single_cache_per_key:* = array();
	                var next_open_comment_multi:* = '';
	                var next_comment_single_key:* = '';
	
	                length = strlen(part);
	                for (i = 0; i < length; ++i) {
	                    // Get the next char
	                    //var char:* = part[i];
	                    var char:* = part.charAt(i);
	                    var char_len:* = 1;
	
	                   var string_started:* = false;
	
	                    if (isset(is_string_starter[char])) {
	                        // Possibly the start of a new string ...
	
	                        //Check which starter it was ...
	                        //Fix for SF#1932083: Multichar Quotemarks unsupported
	                        if (is_array(is_string_starter[char])) {
	                            var char_new:* = '';
	                            //for each (is_string_starter[char] as testchar) {
	                            for (var testchar:* in is_string_starter[char]) {
	                                if (testchar === substr(part, i, strlen(testchar)) &&
	                                    strlen(testchar) > strlen(char_new)) {
	                                    char_new = testchar;
	                                    string_started = true;
	                                }
	                            }
	                            if (string_started) {
	                                char = char_new;
	                            }
	                        } else {
	                            testchar = is_string_starter[char];
	                            if (testchar === substr(part, i, strlen(testchar))) {
	                                char = testchar;
	                                string_started = true;
	                            }
	                        }
	                        char_len = strlen(char);
	                    }
	
	                    if (string_started) {
	                        // Hand out the correct style information for this string
	                        var string_key:* = array_search(char, this.language_data['QUOTEMARKS']);
	                        if (!isset(this.language_data['STYLES']['STRINGS'][string_key]) ||
	                            !isset(this.language_data['STYLES']['ESCAPE_CHAR'][string_key])) {
	                            string_key = 0;
	                        }
							
							var string_attributes:*;
							var escape_char_attributes:*;
							
	                        if (!this.use_classes) {
	                            string_attributes = ' style="' + this.language_data['STYLES']['STRINGS'][string_key] + '"';
	                            escape_char_attributes = ' style="' + this.language_data['STYLES']['ESCAPE_CHAR'][string_key] + '"';
	                        } else {
	                            string_attributes = ' class="st' + string_key + '"';
	                            escape_char_attributes = ' class="es' + string_key + '"';
	                        }
	
	                        // parse the stuff before this
	                        result += this.parse_non_string_part(stuff_to_parse);
	                        stuff_to_parse = '';
	
	                        // now handle the string
	                        var string:* = '';
	
	                        // look for closing quote
	                        var start:* = i;
	                        while (close_pos = strpos(part, char, start + char_len)) {
	                            start = close_pos;
	                            if (this.lexic_permissions['ESCAPE_CHAR'] && part[close_pos - 1] == this.language_data['ESCAPE_CHAR']) {
	                                // check wether this quote is escaped or if it is something like '\\'
	                                var escape_char_pos:* = close_pos - 1;
	                                while (escape_char_pos > 0 &&
	                                        part[escape_char_pos - 1] == this.language_data['ESCAPE_CHAR']) {
	                                    --escape_char_pos;
	                                }
	                                if ((close_pos - escape_char_pos) & 1) {
	                                    // uneven number of escape chars => this quote is escaped
	                                    continue;
	                                }
	                            }
	
	                            // found closing quote
	                            break;
	                        }
	
	                        //Found the closing delimiter?
	                        if (!close_pos) {
	                            // span till the end of this part when no closing delimiter is found
	                            close_pos = length;
	                        }
	
	                        //Get the actual string
	                        string = substr(part, i, close_pos - i + char_len);
	                        i = close_pos + char_len - 1;
	
	                        // handle escape chars and encode html chars
	                        // (special because when we have escape chars within our string they may not be escaped)
	                        if (this.lexic_permissions['ESCAPE_CHAR'] && this.language_data['ESCAPE_CHAR']) {
	                            start = 0;
	                            var new_string:* = '';
	                            var es_pos:*;
	                            while (es_pos = strpos(string, this.language_data['ESCAPE_CHAR'], start)) {
	                                new_string += this.hsc(substr(string, start, es_pos - start))
	                                              + "<spanescape_char_attributes>" + escaped_escape_char;
	                                var es_char:* = string[es_pos + 1];
	                                if (es_char == "\n") {
	                                    // don't put a newline around newlines
	                                    new_string += "</span>\n";
	                                } else if (ord(es_char) >= 128) {
	                                    //This is an non-ASCII char (UTF8 or single byte)
	                                    //This code tries to work around SF#2037598 ...
	                                    if(function_exists('mb_substr')) {
	                                        var es_char_m:* = mb_substr(substr(string, es_pos+1, 16), 0, 1, this.encoding);
	                                        new_string += es_char_m + '</span>';
	                                    } else if (!GESHI_PHP_PRE_433 && 'utf-8' == this.encoding) {
	                                        if(preg_match("/[\xC2-\xDF][\x80-\xBF]"+
	                                            "|\xE0[\xA0-\xBF][\x80-\xBF]"+
	                                            "|[\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}"+
	                                            "|\xED[\x80-\x9F][\x80-\xBF]"+
	                                            "|\xF0[\x90-\xBF][\x80-\xBF]{2}"+
	                                            "|[\xF1-\xF3][\x80-\xBF]{3}"+
	                                            "|\xF4[\x80-\x8F][\x80-\xBF]{2}/s",
	                                            string, es_char_m, null, es_pos + 1)) {
	                                            es_char_m = es_char_m[0];
	                                        } else {
	                                            es_char_m = es_char;
	                                        }
	                                        new_string += this.hsc(es_char_m) + '</span>';
	                                    } else {
	                                        es_char_m = this.hsc(es_char);
	                                    }
	                                    es_pos += strlen(es_char_m) - 1;
	                                } else {
	                                    new_string += this.hsc(es_char) + '</span>';
	                                }
	                                start = es_pos + 2;
	                            }
	                            string = new_string + this.hsc(substr(string, start));
	                            new_string = '';
	                        } else {
	                            string = this.hsc(string);
	                        }
	
	                        if (check_linenumbers) {
	                            // Are line numbers used? If, we should end the string before
	                            // the newline and begin it again (so when <li>s are put in the source
	                            // remains XHTML compliant)
	                            // note to self: This opens up possibility of config files specifying
	                            // that languages can/cannot have multiline strings???
	                            string = str_replace("\n", "</span>\n<spanstring_attributes>", string);
	                        }
	
	                        result += "<spanstring_attributes>" + string + '</span>';
	                        string = '';
	                        continue;
	                    } else if (this.lexic_permissions['STRINGS'] && hq && hq[0] == char &&
	                        substr(part, i, hq_strlen) == hq) {
	                        // The start of a hard quoted string
	                        if (!this.use_classes) {
	                            string_attributes = ' style="' + this.language_data['STYLES']['STRINGS']['HARDQUOTE'] + '"';
	                            escape_char_attributes = ' style="' + this.language_data['STYLES']['ESCAPE_CHAR']['HARDESCAPE'] + '"';
	                        } else {
	                            string_attributes = ' class="st_h"';
	                            escape_char_attributes = ' class="es_h"';
	                        }
	                        // parse the stuff before this
	                        result += this.parse_non_string_part(stuff_to_parse);
	                        stuff_to_parse = '';
	
	                        // now handle the string
	                        string = '';
	
	                        // look for closing quote
	                        start = i + hq_strlen;
	                        
	                        // continue out from 2 levels deep
	                        var continue2:Boolean = false;
	                        
	                        while (close_pos = strpos(part, this.language_data['HARDQUOTE'][1], start)) {
	                            start = close_pos + 1;
	                            if (this.lexic_permissions['ESCAPE_CHAR'] && part[close_pos - 1] == this.language_data['ESCAPE_CHAR']) {
	                                // make sure this quote is not escaped
	                                //for each (this.language_data['HARDESCAPE'] as hardescape) {
	                                for (var hardescape:* in this.language_data['HARDESCAPE']) {
	                                    if (substr(part, close_pos - 1, strlen(hardescape)) == hardescape) {
	                                        // check wether this quote is escaped or if it is something like '\\'
	                                        escape_char_pos = close_pos - 1;
	                                        while (escape_char_pos > 0
	                                                && part[escape_char_pos - 1] == this.language_data['ESCAPE_CHAR']) {
	                                            --escape_char_pos;
	                                        }
	                                        if ((close_pos - escape_char_pos) & 1) {
	                                            // uneven number of escape chars => this quote is escaped
	                                            // continue 2;
	                                            continue2 = true;
	                                            if (continue2) break;
	                                        }
	                                    }
	                                }
	                                
                                    if (continue2) {
                                    	continue2 = false; 
                                    	continue;
                                    }
	                            }
	
	                            // found closing quote
	                            break;
	                        }
	
	                        //Found the closing delimiter?
	                        if (!close_pos) {
	                            // span till the end of this part when no closing delimiter is found
	                            close_pos = length;
	                        }
	
	                        //Get the actual string
	                        string = substr(part, i, close_pos - i + 1);
	                        i = close_pos;
	
	                        // handle escape chars and encode html chars
	                        // (special because when we have escape chars within our string they may not be escaped)
	                        if (this.lexic_permissions['ESCAPE_CHAR'] && this.language_data['ESCAPE_CHAR']) {
	                            start = 0;
	                            new_string = '';
	                            while (es_pos = strpos(string, this.language_data['ESCAPE_CHAR'], start)) {
	                                // hmtl escape stuff before
	                                new_string += this.hsc(substr(string, start, es_pos - start));
	                                // check if this is a hard escape
	                               // for each (this.language_data['HARDESCAPE'] as hardescape) {
	                                for (hardescape in this.language_data['HARDESCAPE']) {
	                                    if (substr(string, es_pos, strlen(hardescape)) == hardescape) {
	                                        // indeed, this is a hardescape
	                                        new_string += "<spanescape_char_attributes>" +
	                                            this.hsc(hardescape) + '</span>';
	                                        start = es_pos + strlen(hardescape);
	                                        // continue 2;
                                            continue2 = true;
                                            if (continue2) break;
	                                    }
	                                }
                                    if (continue2) {
                                    	continue2 = false; 
                                    	continue;
                                    }
	                                // not a hard escape, but a normal escape
	                                // they come in pairs of two
	                                var c:* = 0;
	                                while (isset(string[es_pos + c]) && isset(string[es_pos + c + 1])
	                                    && string[es_pos + c] == this.language_data['ESCAPE_CHAR']
	                                    && string[es_pos + c + 1] == this.language_data['ESCAPE_CHAR']) {
	                                    c += 2;
	                                }
	                                if (c) {
	                                    new_string += "<spanescape_char_attributes>" +
	                                        str_repeat(escaped_escape_char, c) +
	                                        '</span>';
	                                    start = es_pos + c;
	                                } else {
	                                    // this is just a single lonely escape char...
	                                    new_string += escaped_escape_char;
	                                    start = es_pos + 1;
	                                }
	                            }
	                            string = new_string + this.hsc(substr(string, start));
	                        } else {
	                            string = this.hsc(string);
	                        }
	
	                        if (check_linenumbers) {
	                            // Are line numbers used? If, we should end the string before
	                            // the newline and begin it again (so when <li>s are put in the source
	                            // remains XHTML compliant)
	                            // note to self: This opens up possibility of config files specifying
	                            // that languages can/cannot have multiline strings???
	                            string = str_replace("\n", "</span>\n<spanstring_attributes>", string);
	                        }
	
	                        result += "<spanstring_attributes>" + string + '</span>';
	                        string = '';
	                        continue;
	                    } else {
	                        // update regexp comment cache if needed
	                        if (isset(this.language_data['COMMENT_REGEXP']) && next_comment_regexp_pos < i) {
	                            next_comment_regexp_pos = length;
	                            //for each (this.language_data['COMMENT_REGEXP'] as comment_key => regexp) {
	                            for (var comment_key:* in this.language_data['COMMENT_REGEXP']) {
	                            	var regexp:* = this.language_data['COMMENT_REGEXP'][regexp];
	                                var match_i:* = false;
	                                if (isset(comment_regexp_cache_per_key[comment_key]) &&
	                                    comment_regexp_cache_per_key[comment_key] >= i) {
	                                    // we have already matched something
	                                    match_i = comment_regexp_cache_per_key[comment_key];
	                                } else if (
	                                    //This is to allow use of the offset parameter in preg_match and stay as compatible with older PHP versions as possible
	                                    (GESHI_PHP_PRE_433 && preg_match(regexp, substr(part, i), match, PREG_OFFSET_CAPTURE)) ||
	                                    (!GESHI_PHP_PRE_433 && preg_match(regexp, part, match, PREG_OFFSET_CAPTURE, i))
	                                    ) {
	                                    match_i = match[0][1];
	                                    if (GESHI_PHP_PRE_433) {
	                                        match_i += i;
	                                    }
	
	                                    comment_regexp_cache[match_i] = {
	                                        'key': comment_key,
	                                        'length': strlen(match[0][0])
	                                    };
	
	                                    comment_regexp_cache_per_key[comment_key] = match_i;
	                                } else {
	                                    comment_regexp_cache_per_key[comment_key] = false;
	                                    continue;
	                                }
	
	                                if (match_i !== false && match_i < next_comment_regexp_pos) {
	                                    next_comment_regexp_pos = match_i;
	                                    if (match_i === i) {
	                                        break;
	                                    }
	                                }
	                            }
	                        }
	                        //Have a look for regexp comments
	                        if (i == next_comment_regexp_pos) {
	                            COMMENT_MATCHED = true;
	                            var comment:* = comment_regexp_cache[next_comment_regexp_pos];
	                            var test_str:* = this.hsc(substr(part, i, comment['length']));
	
	                            //@todo If remove important do remove here
	                            if (this.lexic_permissions['COMMENTS']['MULTI']) {
	                                if (!this.use_classes) {
	                                    attributes = ' style="' + this.language_data['STYLES']['COMMENTS'][comment['key']] + '"';
	                                } else {
	                                    attributes = ' class="co' + comment['key'] + '"';
	                                }
	
	                                test_str = "<spanattributes>" + test_str + "</span>";
	
	                                // Short-cut through all the multiline code
	                                if (check_linenumbers) {
	                                    // strreplace to put close span and open span around multiline newlines
	                                    test_str = str_replace(
	                                        "\n", "</span>\n<spanattributes>",
	                                        str_replace("\n ", "\n&nbsp;", test_str)
	                                    );
	                                }
	                            }
	
	                            i += comment['length'] - 1;
	
	                            // parse the rest
	                            result += this.parse_non_string_part(stuff_to_parse);
	                            stuff_to_parse = '';
	                        }
	
	                        // If we haven't matched a regexp comment, try multi-line comments
	                        if (!COMMENT_MATCHED) {
	                            // Is this a multiline comment?
	                            if (!empty(this.language_data['COMMENT_MULTI']) && next_comment_multi_pos < i) {
	                                next_comment_multi_pos = length;
	                                //for each (this.language_data['COMMENT_MULTI'] as open => close) {
	                                for (open in this.language_data['COMMENT_MULTI']) {
	                                	close = this.language_data['COMMENT_MULTI'][open];
	                                    match_i = false;
	                                    if (isset(comment_multi_cache_per_key[open]) &&
	                                        comment_multi_cache_per_key[open] >= i) {
	                                        // we have already matched something
	                                        match_i = comment_multi_cache_per_key[open];
	                                    } else if ((match_i = stripos(part, open, i)) !== false) {
	                                        comment_multi_cache_per_key[open] = match_i;
	                                    } else {
	                                        comment_multi_cache_per_key[open] = false;
	                                        continue;
	                                    }
	                                    if (match_i !== false && match_i < next_comment_multi_pos) {
	                                        next_comment_multi_pos = match_i;
	                                        next_open_comment_multi = open;
	                                        if (match_i === i) {
	                                            break;
	                                        }
	                                    }
	                                }
	                            }
	                            if (i == next_comment_multi_pos) {
	                                open = next_open_comment_multi;
	                                close = this.language_data['COMMENT_MULTI'][open];
	                                var open_strlen:* = strlen(open);
	                                var close_strlen:* = strlen(close);
	                                COMMENT_MATCHED = true;
	                                var test_str_match:* = open;
	                                //@todo If remove important do remove here
	                                if (this.lexic_permissions['COMMENTS']['MULTI'] ||
	                                    open == GESHI_START_IMPORTANT) {
	                                    if (open != GESHI_START_IMPORTANT) {
	                                        if (!this.use_classes) {
	                                            attributes = ' style="' + this.language_data['STYLES']['COMMENTS']['MULTI'] + '"';
	                                        } else {
	                                            attributes = ' class="coMULTI"';
	                                        }
	                                        test_str = "<spanattributes>" + this.hsc(open);
	                                    } else {
	                                        if (!this.use_classes) {
	                                            attributes = ' style="' + this.important_styles + '"';
	                                        } else {
	                                            attributes = ' class="imp"';
	                                        }
	
	                                        // We don't include the start of the comment if it's an
	                                        // "important" part
	                                        test_str = "<spanattributes>";
	                                    }
	                                } else {
	                                    test_str = this.hsc(open);
	                                }
	
	                                close_pos = strpos( part, close, i + open_strlen );
	
	                                if (close_pos === false) {
	                                    close_pos = length;
	                                }
	
	                                // Short-cut through all the multiline code
	                                var rest_of_comment:* = this.hsc(substr(part, i + open_strlen, close_pos - i - open_strlen + close_strlen));
	                                if ((this.lexic_permissions['COMMENTS']['MULTI'] ||
	                                    test_str_match == GESHI_START_IMPORTANT) &&
	                                    check_linenumbers) {
	
	                                    // strreplace to put close span and open span around multiline newlines
	                                    test_str += str_replace(
	                                        "\n", "</span>\n<spanattributes>",
	                                        str_replace("\n ", "\n&nbsp;", rest_of_comment)
	                                    );
	                                } else {
	                                    test_str += rest_of_comment;
	                                }
	
	                                if (this.lexic_permissions['COMMENTS']['MULTI'] ||
	                                    test_str_match == GESHI_START_IMPORTANT) {
	                                    test_str += '</span>';
	                                }
	
	                                i = close_pos + close_strlen - 1;
	
	                                // parse the rest
	                                result += this.parse_non_string_part(stuff_to_parse);
	                                stuff_to_parse = '';
	                            }
	                        }
	
	                        // If we haven't matched a multiline comment, try single-line comments
	                        if (!COMMENT_MATCHED) {
	                            // cache potential single line comment occurances
	                            if (!empty(this.language_data['COMMENT_SINGLE']) && next_comment_single_pos < i) {
	                                next_comment_single_pos = length;
	                                //for each (this.language_data['COMMENT_SINGLE'] as comment_key => comment_mark) {
	                                for (comment_key in this.language_data['COMMENT_SINGLE']) {
	                                	var comment_mark:* = this.language_data['COMMENT_SINGLE'][comment_key];
	                                	
	                                    match_i = false;
	                                    if (isset(comment_single_cache_per_key[comment_key]) &&
	                                        comment_single_cache_per_key[comment_key] >= i) {
	                                        // we have already matched something
	                                        match_i = comment_single_cache_per_key[comment_key];
	                                    } else if (
	                                        // case sensitive comments
	                                        (this.language_data['CASE_SENSITIVE'][GESHI_COMMENTS] &&
	                                        (match_i = stripos(part, comment_mark, i)) !== false) ||
	                                        // non case sensitive
	                                        (!this.language_data['CASE_SENSITIVE'][GESHI_COMMENTS] &&
	                                          ((match_i = strpos(part, comment_mark, i)) !== false))) {
	                                        comment_single_cache_per_key[comment_key] = match_i;
	                                    } else {
	                                        comment_single_cache_per_key[comment_key] = false;
	                                        continue;
	                                    }
	                                    if (match_i !== false && match_i < next_comment_single_pos) {
	                                        next_comment_single_pos = match_i;
	                                        next_comment_single_key = comment_key;
	                                        if (match_i === i) {
	                                            break;
	                                        }
	                                    }
	                                }
	                            }
	                            if (next_comment_single_pos == i) {
	                                comment_key = next_comment_single_key;
	                                comment_mark = this.language_data['COMMENT_SINGLE'][comment_key];
	                                var com_len:* = strlen(comment_mark);
	
	                                // This check will find special variables like # in bash
	                                // or compiler directives of Delphi beginning {
	                                if ((empty(sc_disallowed_before) || (i == 0) ||
	                                    (false === strpos(sc_disallowed_before, part[i-1]))) &&
	                                    (empty(sc_disallowed_after) || (length <= i + com_len) ||
	                                    (false === strpos(sc_disallowed_after, part[i + com_len]))))
	                                {
	                                    // this is a valid comment
	                                    COMMENT_MATCHED = true;
	                                    if (this.lexic_permissions['COMMENTS'][comment_key]) {
	                                        if (!this.use_classes) {
	                                            attributes = ' style="' + this.language_data['STYLES']['COMMENTS'][comment_key] + '"';
	                                        } else {
	                                            attributes = ' class="co' + comment_key + '"';
	                                        }
	                                        test_str = "<spanattributes>" + this.hsc(this.change_case(comment_mark));
	                                    } else {
	                                        test_str = this.hsc(comment_mark);
	                                    }
	
	                                    //Check if this comment is the last in the source
	                                    close_pos = strpos(part, "\n", i);
	                                   var oops:* = false;
	                                    if (close_pos === false) {
	                                        close_pos = length;
	                                        oops = true;
	                                    }
	                                    test_str += this.hsc(substr(part, i + com_len, close_pos - i - com_len));
	                                    if (this.lexic_permissions['COMMENTS'][comment_key]) {
	                                        test_str += "</span>";
	                                    }
	
	                                    // Take into account that the comment might be the last in the source
	                                    if (!oops) {
	                                      test_str += "\n";
	                                    }
	
	                                    i = close_pos;
	
	                                    // parse the rest
	                                    result += this.parse_non_string_part(stuff_to_parse);
	                                    stuff_to_parse = '';
	                                }
	                            }
	                        }
	                    }
	
	                    // Where are we adding this char?
	                    if (!COMMENT_MATCHED) {
	                        stuff_to_parse += char;
	                    } else {
	                        result += test_str;
	                        unset(test_str);
	                        COMMENT_MATCHED = false;
	                    }
	                }
	                // Parse the last bit
	                result += this.parse_non_string_part(stuff_to_parse);
	                stuff_to_parse = '';
	            } else {
	                result += this.hsc(part);
	            }
	            // Close the <span> that surrounds the block
	            if (STRICTATTRS != '') {
	                result = str_replace("\n", "</span>\n<spanSTRICTATTRS>", result);
	                result += '</span>';
	            }
	
	            endresult += result;
	            unset(part, parts[key], result);
	        }
	
	        //This fix is related to SF#1923020, but has to be applied regardless of
	        //actually highlighting symbols.
	        /** NOTE: memorypeak #3 */
	        endresult = str_replace(array('<SEMI>', '<PIPE>'), array(';', '|'), endresult);
	
	//        // Parse the last stuff (redundant?)
	//        result += this.parse_non_string_part(stuff_to_parse);
	
	        // Lop off the very first and last spaces
	//        result = substr(result, 1, -1);
	
	        // We're finished: stop timing
	        this.set_time(start_time, microtime());
	
	        this.finalise(endresult);
	        dispatchEvent(new HighlightEvent(HighlightEvent.COMPLETE));
	        return endresult;
	    }
	
	    /**
	     * Swaps out spaces and tabs for HTML indentation. Not needed if
	     * the code is in a pre block...
	     *
	     * @param  string The source to indent (reference!)
	     * @since  1.0.0
	     * @access private
	     */
	    public function indent(result:String):void {
	        /// Replace tabs with the correct number of spaces
	        if (false !== strpos(result, "\t")) {
	            var lines:* = explode("\n", result);
	            result = null;//Save memory while we process the lines individually
	            tab_width = this.get_real_tab_width();
	            var tab_string:* = '&nbsp;' + str_repeat(' ', tab_width);
	
	            for (var key:int = 0, n:int = count(lines); key < n; key++) {
	                var line:* = lines[key];
	                if (false === strpos(line, "\t")) {
	                    continue;
	                }
	
	                var pos:* = 0;
	                var length:* = strlen(line);
	                lines[key] = ''; // reduce memory
	
	                var IN_TAG:* = false;
	                for (var i:uint = 0; i < length; ++i) {
	                    var char:* = line[i];
	                    // Simple engine to work out whether we're in a tag.
	                    // If we are we modify pos. This is so we ignore HTML
	                    // in the line and only workout the tab replacement
	                    // via the actual content of the string
	                    // This test could be improved to include strings in the
	                    // html so that < or > would be allowed in user's styles
	                    // (e.g. quotes: '<' '>'; or similar)
	                    if (IN_TAG) {
	                        if ('>' == char) {
	                            IN_TAG = false;
	                        }
	                        lines[key] += char;
	                    } else if ('<' == char) {
	                        IN_TAG = true;
	                        lines[key] += '<';
	                    } else if ('&' == char) {
	                        var substr:* = substr(line, i + 3, 5);
	                        var posi:* = strpos(substr, ';');
	                        if (false === posi) {
	                            ++pos;
	                        } else {
	                            pos -= posi+2;
	                        }
	                        lines[key] += char;
	                    } else if ("\t" == char) {
	                        var str:* = '';
	                        // OPTIMISE - move strs out. Make an array:
	                        // tabs = array(
	                        //  1 => '&nbsp;',
	                        //  2 => '&nbsp; ',
	                        //  3 => '&nbsp; &nbsp;' etc etc
	                        // to use instead of building a string every time
	                        var tab_end_width:* = tab_width - (pos % tab_width); //Moved out of the look as it doesn't change within the loop
	                        if ((pos & 1) || 1 == tab_end_width) {
	                            str += substr(tab_string, 6, tab_end_width);
	                        } else {
	                            str += substr(tab_string, 0, tab_end_width+5);
	                        }
	                        lines[key] += str;
	                        pos += tab_end_width;
	
	                        if (false === strpos(line, "\t", i + 1)) {
	                            lines[key] += substr(line, i + 1);
	                            break;
	                        }
	                    } else if (0 == pos && ' ' == char) {
	                        lines[key] += '&nbsp;';
	                        ++pos;
	                    } else {
	                        lines[key] += char;
	                        ++pos;
	                    }
	                }
	            }
	            result = implode("\n", lines);
	            unset(lines);//We don't need the lines separated beyond this --- free them!
	        }
	        // Other whitespace
	        // BenBE: Fix to reduce the number of replacements to be done
	        result = preg_replace('/^ /m', '&nbsp;', result);
	        result = str_replace('  ', ' &nbsp;', result);
	
	        if (this.line_numbers == GESHI_NO_LINE_NUMBERS) {
	            if (this.line_ending === null) {
	                result = nl2br(result);
	            } else {
	                result = str_replace("\n", this.line_ending, result);
	            }
	        }
	    }
	
	    /**
	     * Changes the case of a keyword for those languages where a change is asked for
	     *
	     * @param  string The keyword to change the case of
	     * @return string The keyword with its case changed
	     * @since  1.0.0
	     * @access private
	     */
	    public function change_case(instr:String):String {
	        switch (this.language_data['CASE_KEYWORDS']) {
	            case GESHI_CAPS_UPPER:
	                return strtoupper(instr);
	            case GESHI_CAPS_LOWER:
	                return strtolower(instr);
	            default:
	                return instr;
	        }
	    }
	
	    /**
	     * Handles replacements of keywords to include markup and links if requested
	     *
	     * @param  string The keyword to add the Markup to
	     * @return The HTML for the match found
	     * @since  1.0.8
	     * @access private
	     *
	     * @todo   Get rid of ender in keyword links
	     */
	    public function handle_keyword_replace(match:String):String {
	        var k:* = this._kw_replace_group;
	        var keyword:* = match[0];
	
	        var before:* = '';
	        var after:* = '';
	
	        if (this.keyword_links) {
	            // Keyword links have been ebabled
	
	            if (isset(this.language_data['URLS'][k]) &&
	                this.language_data['URLS'][k] != '') {
	                // There is a base group for this keyword
	
	                // Old system: strtolower
	                //keyword = ( this.language_data['CASE_SENSITIVE'][group] ) ? keyword : strtolower(keyword);
	                // New system: get keyword from language file to get correct case
	                if (!this.language_data['CASE_SENSITIVE'][k] &&
	                    strpos(this.language_data['URLS'][k], '{FNAME}') !== false) {
	                    //for each (this.language_data['KEYWORDS'][k] as word) {
	                    for (var word:String in this.language_data['KEYWORDS'][k]) {
	                        if (strcasecmp(word, keyword) == 0) {
	                            break;
	                        }
	                    }
	                } else {
	                    word = keyword;
	                }
	
	                before = '<|UR1|"' +
	                    str_replace(
	                        array('{FNAME}', '{FNAMEL}', '{FNAMEU}', '.'),
	                        array(this.hsc(word), this.hsc(strtolower(word)),
	                            this.hsc(strtoupper(word)), '<DOT>'),
	                        this.language_data['URLS'][k]
	                    ) + '">';
	                after = '</a>';
	            }
	        }
	
	        return before + '<|/'+ k +'/>' + this.change_case(keyword) + '|>' + after;
	    }
	
	    /**
	     * handles regular expressions highlighting-definitions with callback functions
	     *
	     * @note this is a callback, don't use it directly
	     *
	     * @param array the matches array
	     * @return The highlighted string
	     * @since 1.0.8
	     * @access private
	     */
	    public function handle_regexps_callback(matches:Array):String {
	        // before: "' style=\"' + call_user_func(\"func\", '\\1') + '\"\\1|>'",
	        return  ' style="' + call_user_func(this.language_data['STYLES']['REGEXPS'][this._rx_key], matches[1]) + '"' + matches[1] + '|>';
	    }
	
	    /**
	     * handles newlines in REGEXPS matches. Set the _hmr_* vars before calling this
	     *
	     * @note this is a callback, don't use it directly
	     *
	     * @param array the matches array
	     * @return string
	     * @since 1.0.8
	     * @access private
	     */
	    public function handle_multiline_regexps(matches:Array):String {
	        var before:* = this._hmr_before;
	        var after:* = this._hmr_after;
	        if (this._hmr_replace) {
	            var replace:* = this._hmr_replace;
	            var search:* = array();
	
	            //for each (array_keys(matches) as k) {
	            for (var k:* in array_keys(matches)) {
	                search = '\\' + k;
	            }
	
	            before = str_replace(search, matches, before);
	            after = str_replace(search, matches, after);
	            replace = str_replace(search, matches, replace);
	        } else {
	            replace = matches[0];
	        }
	        return before
	                    + '<|!REG3XP' + this._hmr_key + '!>'
	                        + str_replace("\n", "|>\n<|!REG3XP" + this._hmr_key + '!>', replace)
	                    + '|>'
	              + after;
	    }
	
	    /**
	     * Takes a string that has no strings or comments in it, and highlights
	     * stuff like keywords, numbers and methods.
	     *
	     * @param string The string to parse for keyword, numbers etc.
	     * @since 1.0.0
	     * @access private
	     * @todo BUGGY! Why? Why not build string and return?
	     */
	    public function parse_non_string_part(stuff_to_parse:String):String {
	        stuff_to_parse = ' ' + this.hsc(stuff_to_parse);
	
	        // Regular expressions
	        //for each (this.language_data['REGEXPS'] as key => regexp) {
	        for (var key:* in this.language_data['REGEXPS']) {
	        	var regexp:* = this.language_data['REGEXPS'][regexp];
	        	
	            if (this.lexic_permissions['REGEXPS'][key]) {
	                if (is_array(regexp)) {
	                    if (this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                        // produce valid HTML when we match multiple lines
	                        this._hmr_replace = regexp[GESHI_REPLACE];
	                        this._hmr_before = regexp[GESHI_BEFORE];
	                        this._hmr_key = key;
	                        this._hmr_after = regexp[GESHI_AFTER];
	                        stuff_to_parse = preg_replace_callback(
	                            "/" + regexp[GESHI_SEARCH] + "/{regexp[GESHI_MODIFIERS]}",
	                            array(this, 'handle_multiline_regexps'),
	                            stuff_to_parse);
	                        this._hmr_replace = false;
	                        this._hmr_before = '';
	                        this._hmr_after = '';
	                    } else {
	                        stuff_to_parse = preg_replace(
	                            '/' + regexp[GESHI_SEARCH] + '/' + regexp[GESHI_MODIFIERS],
	                            regexp[GESHI_BEFORE] + '<|!REG3XP' + key + '!>' + regexp[GESHI_REPLACE] + '|>' + regexp[GESHI_AFTER],
	                            stuff_to_parse);
	                    }
	                } else {
	                    if (this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                        // produce valid HTML when we match multiple lines
	                        this._hmr_key = key;
	                        stuff_to_parse = preg_replace_callback( "/(" + regexp + ")/",
	                                              array(this, 'handle_multiline_regexps'), stuff_to_parse);
	                        this._hmr_key = '';
	                    } else {
	                        stuff_to_parse = preg_replace( "/(" + regexp + ")/", "<|!REG3XPkey!>\\1|>", stuff_to_parse);
	                    }
	                }
	            }
	        }
	
	        // Highlight numbers. As of 1.0.8 we support diffent types of numbers
	        var numbers_found:* = false;
	        if (this.lexic_permissions['NUMBERS'] && preg_match('#\d#', stuff_to_parse )) {
	            numbers_found = true;
	
	            //For each of the formats ...
	            //for each(this.language_data['NUMBERS_RXCACHE'] as id => regexp) {
	            for (var id:* in this.language_data['NUMBERS_RXCACHE']) {
	            	regexp = this.language_data['NUMBERS_RXCACHE'][id];
	                //Check if it should be highlighted ...
	                stuff_to_parse = preg_replace(regexp, "<|/NUM!id/>\\1|>", stuff_to_parse);
	            }
	        }
	
	        // Highlight keywords
	        var disallowed_before:* = "(?<![a-zA-Z0-9\_\|\#;>|^&";
	        var disallowed_after:* = "(?![a-zA-Z0-9_\|%\\-&;";
	        if (this.lexic_permissions['STRINGS']) {
	            var quotemarks:* = preg_quote(implode(this.language_data['QUOTEMARKS']), '/');
	            disallowed_before += quotemarks;
	            disallowed_after += quotemarks;
	        }
	        disallowed_before += "])";
	        disallowed_after += "])";
	
	        var parser_control_pergroup:* = false;
	        if (isset(this.language_data['PARSER_CONTROL'])) {
	            if (isset(this.language_data['PARSER_CONTROL']['KEYWORDS'])) {
	                var x:* = 0; // check wether per-keyword-group parser_control is enabled
	                if (isset(this.language_data['PARSER_CONTROL']['KEYWORDS']['DISALLOWED_BEFORE'])) {
	                    disallowed_before = this.language_data['PARSER_CONTROL']['KEYWORDS']['DISALLOWED_BEFORE'];
	                    ++x;
	                }
	                if (isset(this.language_data['PARSER_CONTROL']['KEYWORDS']['DISALLOWED_AFTER'])) {
	                    disallowed_after = this.language_data['PARSER_CONTROL']['KEYWORDS']['DISALLOWED_AFTER'];
	                    ++x;
	                }
	                parser_control_pergroup = (count(this.language_data['PARSER_CONTROL']['KEYWORDS']) - x) > 0;
	            }
	        }
	
	        // if this is changed, don't forget to change it below
	//        if (!empty(disallowed_before)) {
	//            disallowed_before = "(?<![disallowed_before])";
	//        }
	//        if (!empty(disallowed_after)) {
	//            disallowed_after = "(?![disallowed_after])";
	//        }
	
	        //for each (array_keys(this.language_data['KEYWORDS']) as k) {
	        for (var k:* in array_keys(this.language_data['KEYWORDS'])) {
	            if (!isset(this.lexic_permissions['KEYWORDS'][k]) ||
	                this.lexic_permissions['KEYWORDS'][k]) {
	
	                var case_sensitive:* = this.language_data['CASE_SENSITIVE'][k];
	                var modifiers:* = case_sensitive ? '' : 'i';
	
	                // NEW in 1.0.8 - per-keyword-group parser control
	                var disallowed_before_local:* = disallowed_before;
	                var disallowed_after_local:* = disallowed_after;
	                if (parser_control_pergroup && isset(this.language_data['PARSER_CONTROL']['KEYWORDS'][k])) {
	                    if (isset(this.language_data['PARSER_CONTROL']['KEYWORDS'][k]['DISALLOWED_BEFORE'])) {
	                        disallowed_before_local =
	                            this.language_data['PARSER_CONTROL']['KEYWORDS'][k]['DISALLOWED_BEFORE'];
	                    }
	
	                    if (isset(this.language_data['PARSER_CONTROL']['KEYWORDS'][k]['DISALLOWED_AFTER'])) {
	                        disallowed_after_local =
	                            this.language_data['PARSER_CONTROL']['KEYWORDS'][k]['DISALLOWED_AFTER'];
	                    }
	                }
	
	                this._kw_replace_group = k;
	
	                //NEW in 1.0.8, the cached regexp list
	                // since we don't want PHP / PCRE to crash due to too large patterns we split them into smaller chunks
	                for (var set1:int = 0, set_length:int = count(this.language_data['CACHED_KEYWORD_LISTS'][k]); set1 <  set_length; ++set1) {
	                    //keywordset =& this.language_data['CACHED_KEYWORD_LISTS'][k][set];
	                    var keywordset:* = keywordset && this.language_data['CACHED_KEYWORD_LISTS'][k][set1];
	                    // Might make a more unique string for putting the number in soon
	                    // Basically, we don't put the styles in yet because then the styles themselves will
	                    // get highlighted if the language has a CSS keyword in it (like CSS, for example ;))
	                    stuff_to_parse = preg_replace_callback(
	                        "/disallowed_before_local({keywordset})(?!\<DOT\>(?:htm|php))disallowed_after_local/modifiers",
	                        array(this, 'handle_keyword_replace'),
	                        stuff_to_parse
	                        );
	                }
	            }
	        }
	
	        //
	        // Now that's all done, replace /[number]/ with the correct styles
	        //
	        //for each (array_keys(this.language_data['KEYWORDS']) as k) {
	        for (k in array_keys(this.language_data['KEYWORDS'])) {
	        	var attributes:*;
	            if (!this.use_classes) {
	                attributes = ' style="' + 
	                    (isset(this.language_data['STYLES']['KEYWORDS'][k]) ?
	                    this.language_data['STYLES']['KEYWORDS'][k] : "") + '"';
	            } else {
	                attributes = ' class="kw' + k + '"';
	            }
	            stuff_to_parse = str_replace("<|/k/>", "<|attributes>", stuff_to_parse);
	        }
	
	        if (numbers_found) {
	            // Put number styles in
	            //for each(this.language_data['NUMBERS_RXCACHE'] as id => regexp) {
	            for (id in this.language_data['NUMBERS_RXCACHE']) {
	            	regexp = this.language_data['NUMBERS_RXCACHE'][id];
	//Commented out for now, as this needs some review ...
	//                if (numbers_permissions & id) {
	                    //Get the appropriate style ...
	                        //Checking for unset styles is done by the style cache builder ...
	                    if (!this.use_classes) {
	                        attributes = ' style="' + this.language_data['STYLES']['NUMBERS'][id] + '"';
	                    } else {
	                        attributes = ' class="nu' + id + '"';
	                    }
	
	                    //Set in the correct styles ...
	                    stuff_to_parse = str_replace("/NUM!id/", attributes, stuff_to_parse);
	//                }
	            }
	        }
	
	        // Highlight methods and fields in objects
	        if (this.lexic_permissions['METHODS'] && this.language_data['OOLANG']) {
	            var oolang_spaces:* = "[\s]*";
	            var oolang_before:* = "";
	            var oolang_after:* = "[a-zA-Z][a-zA-Z0-9_]*";
	            if (isset(this.language_data['PARSER_CONTROL'])) {
	                if (isset(this.language_data['PARSER_CONTROL']['OOLANG'])) {
	                    if (isset(this.language_data['PARSER_CONTROL']['OOLANG']['MATCH_BEFORE'])) {
	                        oolang_before = this.language_data['PARSER_CONTROL']['OOLANG']['MATCH_BEFORE'];
	                    }
	                    if (isset(this.language_data['PARSER_CONTROL']['OOLANG']['MATCH_AFTER'])) {
	                        oolang_after = this.language_data['PARSER_CONTROL']['OOLANG']['MATCH_AFTER'];
	                    }
	                    if (isset(this.language_data['PARSER_CONTROL']['OOLANG']['MATCH_SPACES'])) {
	                        oolang_spaces = this.language_data['PARSER_CONTROL']['OOLANG']['MATCH_SPACES'];
	                    }
	                }
	            }
	
	            //for each (this.language_data['OBJECT_SPLITTERS'] as key => splitter) {
	            for (key in this.language_data['OBJECT_SPLITTERS']) {
	            	var splitter:* = this.language_data['OBJECT_SPLITTERS'][key];
	            	
	                if (false !== strpos(stuff_to_parse, splitter)) {
	                    if (!this.use_classes) {
	                        attributes = ' style="' + this.language_data['STYLES']['METHODS'][key] + '"';
	                    } else {
	                        attributes = ' class="me' + key + '"';
	                    }
	                    stuff_to_parse = preg_replace("/(oolang_before)(" + preg_quote(this.language_data['OBJECT_SPLITTERS'][key], '/') + ")(oolang_spaces)(oolang_after)/", "\\1\\2\\3<|attributes>\\4|>", stuff_to_parse);
	                }
	            }
	        }
	
	        //
	        // Highlight brackets. Yes, I've tried adding a semi-colon to this list.
	        // You try it, and see what happens ;)
	        // TODO: Fix lexic permissions not converting entities if shouldn't
	        // be highlighting regardless
	        //
	        if (this.lexic_permissions['BRACKETS']) {
	            stuff_to_parse = str_replace( this.language_data['CACHE_BRACKET_MATCH'],
	                              this.language_data['CACHE_BRACKET_REPLACE'], stuff_to_parse );
	        }
	
	
	        //FIX for symbol highlighting ...
	        if (this.lexic_permissions['SYMBOLS'] && !empty(this.language_data['SYMBOLS'])) {
	            //Get all matches and throw away those witin a block that is already highlighted... (i.e. matched by a regexp)
	            var pot_symbols:*;
	            var n_symbols:* = preg_match_all("/<\|(?:<DOT>|[^>])+>(?:(?!\|>).*?)\|>|<\/a>|(?:" + this.language_data['SYMBOL_SEARCH'] + ")+/", stuff_to_parse, pot_symbols, PREG_OFFSET_CAPTURE | PREG_SET_ORDER);
	            var global_offset:* = 0;
	            for (var s_id:int = 0; s_id < n_symbols; ++s_id) {
	                var symbol_match:* = pot_symbols[s_id][0][0];
	                if (strpos(symbol_match, '<') !== false || strpos(symbol_match, '>') !== false) {
	                    // already highlighted blocks _must_ include either < or >
	                    // so if this conditional applies, we have to skip this match
	                    continue;
	                }
	                // if we reach this point, we have a valid match which needs to be highlighted
	
	                var symbol_length:* = strlen(symbol_match);
	                var symbol_offset:* = pot_symbols[s_id][0][1];
	                unset(pot_symbols[s_id]);
	                var symbol_end:* = symbol_length + symbol_offset;
	                var symbol_hl:* = "";
	
	                // if we have multiple styles, we have to handle them properly
	                if (this.language_data['MULTIPLE_SYMBOL_GROUPS']) {
	                    var old_sym:* = -1;
	                    var sym_match_syms:*;
	                    // Split the current stuff to replace into its atomic symbols ...
	                    preg_match_all("/" + this.language_data['SYMBOL_SEARCH'] + "/", symbol_match, sym_match_syms, PREG_PATTERN_ORDER);
	                    //for each (sym_match_syms[0] as sym_ms) {
	                    for (var sym_ms:* in sym_match_syms[0]) {
	                    	
	                        //Check if consequtive symbols belong to the same group to save output ...
	                        if (isset(this.language_data['SYMBOL_DATA'][sym_ms])
	                            && (this.language_data['SYMBOL_DATA'][sym_ms] != old_sym)) {
	                            if (-1 != old_sym) {
	                                symbol_hl += "|>";
	                            }
	                            old_sym = this.language_data['SYMBOL_DATA'][sym_ms];
	                            if (!this.use_classes) {
	                                symbol_hl += '<| style="' + this.language_data['STYLES']['SYMBOLS'][old_sym] + '">';
	                            } else {
	                                symbol_hl += '<| class="sy' + old_sym + '">';
	                            }
	                        }
	                        symbol_hl += sym_ms;
	                    }
	                    unset(sym_match_syms);
	
	                    //Close remaining tags and insert the replacement at the right position ...
	                    //Take caution if symbol_hl is empty to avoid doubled closing spans.
	                    if (-1 != old_sym) {
	                        symbol_hl += "|>";
	                    }
	                } else {
	                    if (!this.use_classes) {
	                        symbol_hl = '<| style="' + this.language_data['STYLES']['SYMBOLS'][0] + '">';
	                    } else {
	                        symbol_hl = '<| class="sy0">';
	                    }
	                    symbol_hl += symbol_match + '|>';
	                }
	
	
	                stuff_to_parse = substr_replace(stuff_to_parse, symbol_hl, symbol_offset + global_offset, symbol_length);
	
	                // since we replace old text with something of different size,
	                // we'll have to keep track of the differences
	                global_offset += strlen(symbol_hl) - symbol_length;
	            }
	        }
	        //FIX for symbol highlighting ...
	
	        // Add class/style for regexps
	        //for each (array_keys(this.language_data['REGEXPS']) as key) {
	        for (key in array_keys(this.language_data['REGEXPS'])) {
	            if (this.lexic_permissions['REGEXPS'][key]) {
	                if (is_callable(this.language_data['STYLES']['REGEXPS'][key])) {
	                    this._rx_key = key;
	                    stuff_to_parse = preg_replace_callback("/!REG3XPkey!(.*)\|>/U",
	                        array(this, 'handle_regexps_callback'),
	                        stuff_to_parse);
	                } else {
	                    if (!this.use_classes) {
	                        attributes = ' style="' + this.language_data['STYLES']['REGEXPS'][key] + '"';
	                    } else {
	                        if (is_array(this.language_data['REGEXPS'][key]) &&
	                            array_key_exists(GESHI_CLASS, this.language_data['REGEXPS'][key])) {
	                            attributes = ' class="' +
	                                this.language_data['REGEXPS'][key][GESHI_CLASS] + '"';
	                        } else {
	                           attributes = ' class="re' + key + '"';
	                        }
	                    }
	                    stuff_to_parse = str_replace("!REG3XPkey!", "attributes", stuff_to_parse);
	                }
	            }
	        }
	
	        // Replace <DOT> with . for urls
	        stuff_to_parse = str_replace('<DOT>', '.', stuff_to_parse);
	        // Replace <|UR1| with <a href= for urls also
	        if (isset(this.link_styles[GESHI_LINK])) {
	            if (this.use_classes) {
	                stuff_to_parse = str_replace('<|UR1|', '<a' + this.link_target + ' href=', stuff_to_parse);
	            } else {
	                stuff_to_parse = str_replace('<|UR1|', '<a' + this.link_target + ' style="' + this.link_styles[GESHI_LINK] + '" href=', stuff_to_parse);
	            }
	        } else {
	            stuff_to_parse = str_replace('<|UR1|', '<a' + this.link_target + ' href=', stuff_to_parse);
	        }
	
	        //
	        // NOW we add the span thingy ;)
	        //
	
	        stuff_to_parse = str_replace('<|', '<span', stuff_to_parse);
	        stuff_to_parse = str_replace ( '|>', '</span>', stuff_to_parse );
	        return substr(stuff_to_parse, 1);
	    }
	
	    /**
	     * Sets the time taken to parse the code
	     *
	     * @param microtime The time when parsing started
	     * @param microtime The time when parsing ended
	     * @since 1.0.2
	     * @access private
	     */
	    public function set_time(start_time:*, end_time:*):void {
	        var start:* = explode(' ', start_time);
	        var end:* = explode(' ', end_time);
	        this.time = end[0] + end[1] - start[0] - start[1];
	    }
	
	    /**
	     * Gets the time taken to parse the code
	     *
	     * @return double The time taken to parse the code
	     * @since  1.0.2
	     */
	    public function get_time():uint {
	        return this.time;
	    }
	
	    /**
	     * Merges arrays recursively, overwriting values of the first array with values of later arrays
	     *
	     * @since 1.0.8
	     * @access private
	     */
	    public function merge_arrays(...args):* {
	        var arrays:* = args;
	        var narrays:* = count(arrays);
	
	        // check arguments
	        // comment out if more performance is necessary (in this case the for each loop will trigger a warning if the argument is not an array)
	        for (var i:int = 0; i < narrays; i ++) {
	            if (!is_array(arrays[i])) {
	                // also array_merge_recursive returns nothing in this case
	                trigger_error('Argument #' + (i+1) + ' is not an array - trying to merge array with scalar! Returning false!', E_USER_WARNING);
	                return false;
	            }
	        }
	
	        // the first array is in the output set in every case
	        var ret:* = arrays[0];
	
	        // merege ret with the remaining arrays
	        for (i = 1; i < narrays; i ++) {
	            //for each (arrays[i] as key => value) {
	            for (var key:* in arrays[i]) {
	            	var value:* = arrays[i][key];
	            	
	                if (is_array(value) && isset(ret[key])) {
	                    // if ret[key] is not an array you try to merge an scalar value with an array - the result is not defined (incompatible arrays)
	                    // in this case the call will trigger an E_USER_WARNING and the ret[key] will be false.
	                    ret[key] = this.merge_arrays(ret[key], value);
	                } else {
	                    ret[key] = value;
	                }
	            }
	        }
	
	        return ret;
	    }
	
	    /**
	     * Gets language information and stores it for later use
	     *
	     * @param string The filename of the language file you want to load
	     * @since 1.0.0
	     * @access private
	     * @todo Needs to load keys for lexic permissions for keywords, regexps etc
	     */
	    public function load_language(file_name:String, language:String):void {
	        if (file_name == this.loaded_language) {
	            // this file is already loaded!
	            return;
	        }
	
	        //Prepare some stuff before actually loading the language file
	        this.loaded_language = file_name;
	        this.parse_cache_built = false;
	        this.enable_highlighting();
	        var language_data:* = array();
	
	        //Load the language file
	        //require file_name;
	        for (var cached_language:String in this.language_cache) {
	        	if (language==cached_language) {
	        		language_data = this.language_cache[cached_language];
	        	}
	        }
	
	        // Perhaps some checking might be added here later to check that
	        // language data is a valid thing but maybe not
	        this.language_data = language_data;
	
	        // Set strict mode if should be set
	        this.strict_mode = this.language_data['STRICT_MODE_APPLIES'];
	
	        // Set permissions for all lexics to true
	        // so they'll be highlighted by default
	        //for each (array_keys(this.language_data['KEYWORDS']) as key) {
	        for (var key:* in array_keys(this.language_data['KEYWORDS'])) {
	            if (!empty(this.language_data['KEYWORDS'][key])) {
	                this.lexic_permissions['KEYWORDS'][key] = true;
	            } else {
	                this.lexic_permissions['KEYWORDS'][key] = false;
	            }
	        }
			var o:* = this.lexic_permissions['COMMENTS'];
	        //for each (array_keys(this.language_data['COMMENT_SINGLE']) as key) {
	        for (key in array_keys(this.language_data['COMMENT_SINGLE'])) {
	            this.lexic_permissions['COMMENTS'][key] = true;
	        }
	        for (key in array_keys(this.language_data['REGEXPS'])) {
	            this.lexic_permissions['REGEXPS'][key] = true;
	        }
	
	        // for BenBE and future code reviews:
	        // we can use empty here since we only check for existance and emptiness of an array
	        // if it is not an array at all but rather false or null this will work as intended as well
	        // even if this.language_data['PARSER_CONTROL'] is undefined this won't trigger a notice
	        if (isset_drilldown(this.language_data,'PARSER_CONTROL','ENABLE_FLAGS')) {
	            //for each (this.language_data['PARSER_CONTROL']['ENABLE_FLAGS'] as flag => value) {
	            for (var flag:* in this.language_data['PARSER_CONTROL']['ENABLE_FLAGS']) {
	            	var value:* = this.language_data['PARSER_CONTROL']['ENABLE_FLAGS'][flag];
	            	
	                // it's either true or false and maybe is true as well
	                var perm:* = value !== GESHI_NEVER;
	                if (flag == 'ALL') {
	                    this.enable_highlighting(perm);
	                    continue;
	                }
	                if (!isset(this.lexic_permissions[flag])) {
	                    // unknown lexic permission
	                    continue;
	                }
	                if (is_array(this.lexic_permissions[flag])) {
	                    //for each (this.lexic_permissions[flag] as key => val) {
	                    for (key in this.lexic_permissions[flag]) {
	                    	var val:* = this.lexic_permissions[flag][key];
	                        this.lexic_permissions[flag][key] = perm;
	                    }
	                } else {
	                    this.lexic_permissions[flag] = perm;
	                }
	            }
	            unset(this.language_data['PARSER_CONTROL']['ENABLE_FLAGS']);
	        }
			
	        //NEW in 1.0.8: Allow styles to be loaded from a separate file to override defaults
	        var style_filename:* = substr(file_name, 0, -4) + '.style.php';
	        var style_data:*;
	        if (is_readable(style_filename)) {
	            //Clear any style_data that could have been set before ...
	            if (isset(style_data)) {
	                unset(style_data);
	            }
	
	            //Read the Style Information from the style file
	            //include style_filename;
	
	            //Apply the new styles to our current language styles
	            if (isset(style_data) && is_array(style_data)) {
	                this.language_data['STYLES'] = this.merge_arrays(this.language_data['STYLES'], style_data);
	            }
	        }
	
	        // Set default class for CSS
	        this.overall_class = this.language;
	    }
	
	    /**
	     * Takes the parsed code and various options, and creates the HTML
	     * surrounding it to make it look nice.
	     *
	     * @param  string The code already parsed (reference!)
	     * @since  1.0.0
	     * @access private
	     */
	    public function finalise(parsed_code:String):void {
	        // Remove end parts of important declarations
	        // This is BUGGY!! My fault for bad code: fix coming in 1.2
	        // @todo Remove this crap
	        if (this.enable_important_blocks &&
	            (strpos(parsed_code, this.hsc(GESHI_START_IMPORTANT)) === false)) {
	            parsed_code = str_replace(this.hsc(GESHI_END_IMPORTANT), '', parsed_code);
	        }
	
	        // Add HTML whitespace stuff if we're using the <div> header
	        if (this.header_type != GESHI_HEADER_PRE && this.header_type != GESHI_HEADER_PRE_VALID) {
	            this.indent(parsed_code);
	        }
	
	        // purge some unnecessary stuff
	        /** NOTE: memorypeak #1 */
	        parsed_code = preg_replace('#<span[^>]+>(\s*)</span>#', '\\1', parsed_code);
	
	        // If we are using IDs for line numbers, there needs to be an overall
	        // ID set to prevent collisions.
	        if (this.add_ids && !this.overall_id) {
	            this.overall_id = 'geshi-' + substr(md5(microtime()), 0, 4);
	        }
	
	        // Get code into lines
	        /** NOTE: memorypeak #2 */
	        var code:* = explode("\n", parsed_code);
	        parsed_code = this.header();
	
	        // If we're using line numbers, we insert <li>s and appropriate
	        // markup to style them (otherwise we don't need to do anything)
	        if (this.line_numbers != GESHI_NO_LINE_NUMBERS && this.header_type != GESHI_HEADER_PRE_TABLE) {
	            // If we're using the <pre> header, we shouldn't add newlines because
	            // the <pre> will line-break them (and the <li>s already do this for us)
	            var ls:* = (this.header_type != GESHI_HEADER_PRE && this.header_type != GESHI_HEADER_PRE_VALID) ? "\n" : '';
	
	            // Set vars to defaults for following loop
	            var i:* = 0;
	            var n:* = 0;
	            var attrs:*;
	            var def_attr:*;
	            var start:*;
	            var end:*;
	
	            // Foreach line...
	            for (i = 0, n = count(code); i < n;) {
	                //Reset the attributes for a new line ...
	                attrs = array();
	
	                // Make lines have at least one space in them if they're empty
	                // BenBE: Checking emptiness using trim instead of relying on blanks
	                if ('' == trim(code[i])) {
	                    code[i] = '&nbsp;';
	                }
	
	                // If this is a "special line"...
	                if (this.line_numbers == GESHI_FANCY_LINE_NUMBERS &&
	                    i % this.line_nth_row == (this.line_nth_row - 1)) {
	                    // Set the attributes to style the line
	                    if (this.use_classes) {
	                        //attr = ' class="li2"';
	                        attrs['class'] = 'li2';
	                        def_attr = ' class="de2"';
	                    } else {
	                        //attr = ' style="' + this.line_style2 + '"';
	                        attrs['style'] = this.line_style2;
	                        // This style "covers up" the special styles set for special lines
	                        // so that styles applied to special lines don't apply to the actual
	                        // code on that line
	                        def_attr = ' style="' + this.code_style + '"';
	                    }
	                } else {
	                    if (this.use_classes) {
	                        //attr = ' class="li1"';
	                        attrs['class'] = 'li1';
	                        def_attr = ' class="de1"';
	                    } else {
	                        //attr = ' style="' + this.line_style1 + '"';
	                        attrs['style'] = this.line_style1;
	                        def_attr = ' style="' + this.code_style + '"';
	                    }
	                }
	
	                //Check which type of tag to insert for this line
	                if (this.header_type == GESHI_HEADER_PRE_VALID) {
	                    start = "<predef_attr>";
	                    end = '</pre>';
	                } else {
	                    // Span or div?
	                    start = "<divdef_attr>";
	                    end = '</div>';
	                }
	
	                ++i;
	
	                // Are we supposed to use ids? If so, add them
	                if (this.add_ids) {
	                    attrs['id'] = "this.overall_id-i";
	                }
	
	                //Is this some line with extra styles???
	                if (in_array(i, this.highlight_extra_lines)) {
	                    if (this.use_classes) {
	                        if (isset(this.highlight_extra_lines_styles[i])) {
	                            attrs['class'] = "lxi";
	                        } else {
	                            attrs['class'] = "ln-xtra";
	                        }
	                    } else {
	                        array_push(attrs['style'], this.get_line_style(i));
	                    }
	                }
	
	                // Add in the line surrounded by appropriate list HTML
	                var attr_string:* = '';
	                //for each (attrs as key => attr) {
	                for (var key:* in attrs) {
	                	var attr:* = attrs[key];
	                    attr_string += ' ' + key + '="' + implode(' ', attr) + '"';
	                }
	
	                parsed_code += "<liattr_string>start{code[i-1]}end</li>ls";
	                unset(code[i - 1]);
	            }
	        } else {
	            n = count(code);
	            var attributes:*;
	            if (this.use_classes) {
	                attributes = ' class="de1"';
	            } else {
	                attributes = ' style="'+ this.code_style +'"';
	            }
	            if (this.header_type == GESHI_HEADER_PRE_VALID) {
	                parsed_code += '<pre'+ attributes +'>';
	            } 
	            else if (this.header_type == GESHI_HEADER_PRE_TABLE) {
	                if (this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                    if (this.use_classes) {
	                        attrs = ' class="ln"';
	                    } else {
	                        attrs = ' style="'+ this.table_linenumber_style +'"';
	                    }
	                    parsed_code += '<td'+attrs+'><pre>';
	                    
	                    // get linenumbers
	                    // we don't merge it with the for below, since it should be better for
	                    // memory consumption this way
	                    for (i = 1; i <= n; ++i) {
	                        parsed_code += i;
	                        if (i != n) {
	                            parsed_code += "\n";
	                        }
	                    }
	                    parsed_code += '</pre></td><td>';
	                }
	                parsed_code += '<pre'+ attributes +'>';
	            }
	            // No line numbers, but still need to handle highlighting lines extra.
	            // Have to use divs so the full width of the code is highlighted
	            var close:* = 0;
	            for (i = 0; i < n; ++i) {
	                // Make lines have at least one space in them if they're empty
	                // BenBE: Checking emptiness using trim instead of relying on blanks
	                if ('' == trim(code[i])) {
	                    code[i] = '&nbsp;';
	                }
	                // fancy lines
	                if (this.line_numbers == GESHI_FANCY_LINE_NUMBERS &&
	                    i % this.line_nth_row == (this.line_nth_row - 1)) {
	                    // Set the attributes to style the line
	                    if (this.use_classes) {
	                        parsed_code += '<span class="xtra li2"><span class="de2">';
	                    } else {
	                        // This style "covers up" the special styles set for special lines
	                        // so that styles applied to special lines don't apply to the actual
	                        // code on that line
	                        parsed_code += '<span style="display:block;' + this.line_style2 + '">'
	                                          + '<span style="' + this.code_style + '">';
	                    }
	                    close += 2;
	                }
	                //Is this some line with extra styles???
	                if (in_array(i + 1, this.highlight_extra_lines)) {
	                    if (this.use_classes) {
	                        if (isset(this.highlight_extra_lines_styles[i])) {
	                            parsed_code += "<span class=\"xtra lxi\">";
	                        } else {
	                            parsed_code += "<span class=\"xtra ln-xtra\">";
	                        }
	                    } else {
	                        parsed_code += "<span style=\"display:block;" + this.get_line_style(i) + "\">";
	                    }
	                    ++close;
	                }
	
	                parsed_code += code[i];
	
	                if (close) {
	                  parsed_code += str_repeat('</span>', close);
	                  close = 0;
	                }
	                else if (i + 1 < n) {
	                    parsed_code += "\n";
	                }
	                unset(code[i]);
	            }
	
	            if (this.header_type == GESHI_HEADER_PRE_VALID || this.header_type == GESHI_HEADER_PRE_TABLE) {
	                parsed_code += '</pre>';
	            }
	            if (this.header_type == GESHI_HEADER_PRE_TABLE && this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                parsed_code += '</td>';
	            }
	        }
	
	        parsed_code += this.footer();
	    }
	
	    /**
	     * Creates the header for the code block (with correct attributes)
	     *
	     * @return string The header for the code block
	     * @since  1.0.0
	     * @access private
	     */
	    public function header():String {
	        // Get attributes needed
	        /**
	         * @todo   Document behaviour change - class is outputted regardless of whether
	         *         we're using classes or not. Same with style
	         */
	        var attributes:*;
	        attributes = ' class="' + this.language;
	        if (this.overall_class != '') {
	            attributes += " "+this.overall_class;
	        }
	        attributes += '"';
	
	        if (this.overall_id != '') {
	            attributes += " id=\"{this.overall_id}\"";
	        }
	        if (this.overall_style != '') {
	            attributes += ' style="' + this.overall_style + '"';
	        }
	
	        var ol_attributes:* = '';
	
	        if (this.line_numbers_start != 1) {
	            ol_attributes += ' start="' + this.line_numbers_start + '"';
	        }
	
	        // Get the header HTML
	        var header:* = this.header_content;
	        var attr:*;
	        if (header) {
	            if (this.header_type == GESHI_HEADER_PRE || this.header_type == GESHI_HEADER_PRE_VALID) {
	                header = str_replace("\n", '', header);
	            }
	            header = this.replace_keywords(header);

	            if (this.use_classes) {
	                attr = ' class="head"';
	            } else {
	                attr = " style=\"{this.header_content_style}\"";
	            }
	            if (this.header_type == GESHI_HEADER_PRE_TABLE && this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                header = "<thead><tr><td colspan=\"2\" attr>header</td></tr></thead>";
	            } else {
	                header = "<divattr>header</div>";
	            }
	        }
	
	        if (GESHI_HEADER_NONE == this.header_type) {
	            if (this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                return "header<olattributesol_attributes>";
	            }
	            return header + (this.force_code_block ? '<div>' : '');
	        }
	
	        // Work out what to return and do it
	        if (this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	            if (this.header_type == GESHI_HEADER_PRE) {
	                return "<preattributes>header<olol_attributes>";
	            } else if (this.header_type == GESHI_HEADER_DIV ||
	                this.header_type == GESHI_HEADER_PRE_VALID) {
	                return "<divattributes>header<olol_attributes>";
	            } else if (this.header_type == GESHI_HEADER_PRE_TABLE) {
	                return "<tableattributes>header<tbody><tr class=\"li1\">";
	            }
	        } else {
	            if (this.header_type == GESHI_HEADER_PRE) {
	                return "<preattributes>header" + (this.force_code_block ? '<div>' : '');
	            } else {
	                return "<divattributes>header" + (this.force_code_block ? '<div>' : '');
	            }
	        }
	        // to appease compiler
	        return "";
	    }
	
	    /**
	     * Returns the footer for the code block.
	     *
	     * @return string The footer for the code block
	     * @since  1.0.0
	     * @access private
	     */
	    public function footer():String {
	        var footer:* = this.footer_content;
	        // created for the condition below this.linenumbers
	        var linenumbers:*;
	        if (footer) {
	            if (this.header_type == GESHI_HEADER_PRE) {
	                footer = str_replace("\n", '', footer);;
	            }
	            footer = this.replace_keywords(footer);
				var attr:*;
	            if (this.use_classes) {
	                attr = ' class="foot"';
	            } else {
	                attr = " style=\"{this.footer_content_style}\"";
	            }
	            //if (this.header_type == GESHI_HEADER_PRE_TABLE && this.linenumbers != GESHI_NO_LINE_NUMBERS) {
	            if (this.header_type == GESHI_HEADER_PRE_TABLE && linenumbers != GESHI_NO_LINE_NUMBERS) {
	                footer = "<tfoot><tr><td colspan=\"2\">footer</td></tr></tfoot>";
	            } else {
	                footer = "<divattr>footer</div>";
	            }
	        }
	
	        if (GESHI_HEADER_NONE == this.header_type) {
	            return (this.line_numbers != GESHI_NO_LINE_NUMBERS) ? '</ol>' + footer : footer;
	        }
	
	        if (this.header_type == GESHI_HEADER_DIV || this.header_type == GESHI_HEADER_PRE_VALID) {
	            if (this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                return "</ol>footer</div>";
	            }
	            return (this.force_code_block ? '</div>' : '') +
	                "footer</div>";
	        }
	        else if (this.header_type == GESHI_HEADER_PRE_TABLE) {
	            if (this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                return "</tr></tbody>footer</table>";
	            }
	            return (this.force_code_block ? '</div>' : '') +
	                "footer</div>";
	        }
	        else {
	            if (this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	                return "</ol>footer</pre>";
	            }
	            return (this.force_code_block ? '</div>' : '') +
	                "footer</pre>";
	        }
	    }
	
	    /**
	     * Replaces certain keywords in the header and footer with
	     * certain configuration values
	     *
	     * @param  string The header or footer content to do replacement on
	     * @return string The header or footer with replaced keywords
	     * @since  1.0.2
	     * @access private
	     */
	    public function replace_keywords(instr:String):String {
	    	var replacements:*;
	    	var keywords:*;
	    	var speed:*;
	       	keywords = replacements = array();
	
	        keywords = '<TIME>';
	        keywords = '{TIME}';
	        replacements = replacements = number_format(time = this.get_time(), 3);
	
	        keywords = '<LANGUAGE>';
	        keywords = '{LANGUAGE}';
	        replacements = replacements = this.language_data['LANG_NAME'];
	
	        keywords = '<VERSION>';
	        keywords = '{VERSION}';
	        replacements = replacements = GESHI_VERSION;
	
	        keywords = '<SPEED>';
	        keywords = '{SPEED}';
	        if (time <= 0) {
	            speed = 'N/A';
	        } else {
	            speed = strlen(this.source) / time;
	            if (speed >= 1024) {
	                speed = sprintf("%.2f KB/s", speed / 1024.0);
	            } else {
	                speed = sprintf("%.0f B/s", speed);
	            }
	        }
	        replacements = replacements = speed;
	
	        return str_replace(keywords, replacements, instr);
	    }
	
	    /**
	     * Secure replacement for PHP built-in function htmlspecialchars().
	     *
	     * See ticket #427 (http://wush.net/trac/wikka/ticket/427) for the rationale
	     * for this replacement function.
	     *
	     * The INTERFACE for this function is almost the same as that for
	     * htmlspecialchars(), with the same default for quote style; however, there
	     * is no 'charset' parameter. The reason for this is as follows:
	     *
	     * The PHP docs say:
	     *      "The third argument charset defines character set used in conversion."
	     *
	     * I suspect PHP's htmlspecialchars() is working at the byte-value level and
	     * thus _needs_ to know (or asssume) a character set because the special
	     * characters to be replaced could exist at different code points in
	     * different character sets. (If indeed htmlspecialchars() works at
	     * byte-value level that goes some  way towards explaining why the
	     * vulnerability would exist in this function, too, and not only in
	     * htmlentities() which certainly is working at byte-value level.)
	     *
	     * This replacement function however works at character level and should
	     * therefore be "immune" to character set differences - so no charset
	     * parameter is needed or provided. If a third parameter is passed, it will
	     * be silently ignored.
	     *
	     * In the OUTPUT there is a minor difference in that we use '&#39;' instead
	     * of PHP's '&#039;' for a single quote: this provides compatibility with
	     *      get_html_translation_table(HTML_SPECIALCHARS, ENT_QUOTES)
	     * (see comment by mikiwoz at yahoo dot co dot uk on
	     * http://php.net/htmlspecialchars); it also matches the entity definition
	     * for XML 1.0
	     * (http://www.w3.org/TR/xhtml1/dtds.html#a_dtd_Special_characters).
	     * Like PHP we use a numeric character reference instead of '&apos;' for the
	     * single quote. For the other special characters we use the named entity
	     * references, as PHP is doing.
	     *
	     * @author      {@link http://wikkawiki.org/JavaWoman Marjolein Katsma}
	     *
	     * @license     http://www.gnu.org/copyleft/lgpl.html
	     *              GNU Lesser General Public License
	     * @copyright   Copyright 2007, {@link http://wikkawiki.org/CreditsPage
	     *              Wikka Development Team}
	     *
	     * @access      private
	     * @param       string  string string to be converted
	     * @param       integer quote_style
	     *                      - ENT_COMPAT:   escapes &, <, > and double quote (default)
	     *                      - ENT_NOQUOTES: escapes only &, < and >
	     *                      - ENT_QUOTES:   escapes &, <, >, double and single quotes
	     * @return      string  converted string
	     * @since       1.0.7.18
	     */
	    public function hsc(string:String, quote_style:* = null):String {
	    	if (quote_style==null) quote_style = ENT_COMPAT;
	    	
	        // init
	        var aTransSpecchar:Object = {
	            '&': '&amp;',
	            '"': '&quot;',
	            '<': '&lt;',
	            '>': '&gt;',
	
	            //This fix is related to SF#1923020, but has to be applied
	            //regardless of actually highlighting symbols.
	
	            //Circumvent a bug with symbol highlighting
	            //This is required as ; would produce undesirable side-effects if it
	            //was not to be processed as an entity.
	            ';': '<SEMI>', // Force ; to be processed as entity
	            '|': '<PIPE>' // Force | to be processed as entity
	        };                 // ENT_COMPAT set
	
	        switch (quote_style) {
	            case ENT_NOQUOTES: // don't convert double quotes
	                unset(aTransSpecchar['"']);
	                break;
	            case ENT_QUOTES: // convert single quotes as well
	                aTransSpecchar["'"] = '&#39;'; // (apos) htmlspecialchars() uses '&#039;'
	                break;
	        }
	
	        // return translated string
	        var translatedString:* = strtr(string, aTransSpecchar);
	        return translatedString;
	    }
	
	    /**
	     * Returns a stylesheet for the highlighted code. If economy mode
	     * is true, we only return the stylesheet declarations that matter for
	     * this code block instead of the whole thing
	     *
	     * @param  boolean Whether to use economy mode or not
	     * @return string A stylesheet built on the data for the current language
	     * @since  1.0.0
	     */
	    public function get_stylesheet(economy_mode:Boolean = true):String {
	        // If there's an error, chances are that the language file
	        // won't have populated the language data file, so we can't
	        // risk getting a stylesheet...
	        if (this.error) {
	            return '';
	        }
	
	        //Check if the style rearrangements have been processed ...
	        //This also does some preprocessing to check which style groups are useable ...
	        if(!isset(this.language_data['NUMBERS_CACHE'])) {
	            this.build_style_cache();
	        }
			
			var selector:*;
	        // First, work out what the selector should be. If there's an ID,
	        // that should be used, the same for a class. Otherwise, a selector
	        // of '' means that these styles will be applied anywhere
	        if (this.overall_id) {
	            selector = '#' + this.overall_id;
	        } else {
	            selector = '.' + this.language;
	            if (this.overall_class) {
	                selector += '.' + this.overall_class;
	            }
	        }
	        selector += ' ';
	        
			var stylesheet:*;
	        // Header of the stylesheet
	        if (!economy_mode) {
	            stylesheet = "/**\n"+
	                " * GeSHi Dynamically Generated Stylesheet\n"+
	                " * --------------------------------------\n"+
	                " * Dynamically generated stylesheet for {this.language}\n"+
	                " * CSS class: {this.overall_class}, CSS id: {this.overall_id}\n"+
	                " * GeSHi (C) 2004 - 2007 Nigel McNie, 2007 - 2008 Benny Baumann\n" +
	                " * (http://qbnz.com/highlighter/ and http://geshi.org/)\n"+
	                " * --------------------------------------\n"+
	                " */\n";
	        } else {
	            stylesheet = "/**\n"+
	                " * GeSHi (C) 2004 - 2007 Nigel McNie, 2007 - 2008 Benny Baumann\n" +
	                " * (http://qbnz.com/highlighter/ and http://geshi.org/)\n"+
	                " */\n";
	        }
	
	        // Set the <ol> to have no effect at all if there are line numbers
	        // (<ol>s have margins that should be destroyed so all layout is
	        // controlled by the set_overall_style method, which works on the
	        // <pre> or <div> container). Additionally, set default styles for lines
	        if (!economy_mode || this.line_numbers != GESHI_NO_LINE_NUMBERS) {
	            //stylesheet += "selector, {selector}ol, {selector}ol li {margin: 0;}\n";
	            stylesheet += "selector.de1, selector.de2 {{this.code_style}}\n";
	        }
	
	        // Add overall styles
	        // note: neglect economy_mode, empty styles are meaningless
	        if (this.overall_style != '') {
	            stylesheet += "selector {{this.overall_style}}\n";
	        }
	
	        // Add styles for links
	        // note: economy mode does not make _any_ sense here
	        //       either the style is empty and thus no selector is needed
	        //       or the appropriate key is given.
	        //for each (this.link_styles as key => style) {
	        for (var key:* in this.link_styles) {
	        	var style:* = this.link_styles[key];
	        	
	            if (style != '') {
	                switch (key) {
	                    case GESHI_LINK:
	                        stylesheet += "{selector}a:link {{style}}\n";
	                        break;
	                    case GESHI_HOVER:
	                        stylesheet += "{selector}a:hover {{style}}\n";
	                        break;
	                    case GESHI_ACTIVE:
	                        stylesheet += "{selector}a:active {{style}}\n";
	                        break;
	                    case GESHI_VISITED:
	                        stylesheet += "{selector}a:visited {{style}}\n";
	                        break;
	                }
	            }
	        }
	
	        // Header and footer
	        // note: neglect economy_mode, empty styles are meaningless
	        if (this.header_content_style != '') {
	            stylesheet += "selector.head {{this.header_content_style}}\n";
	        }
	        if (this.footer_content_style != '') {
	            stylesheet += "selector.foot {{this.footer_content_style}}\n";
	        }
	
	        // Styles for important stuff
	        // note: neglect economy_mode, empty styles are meaningless
	        if (this.important_styles != '') {
	            stylesheet += "selector.imp {{this.important_styles}}\n";
	        }
	
	        // Simple line number styles
	        if ((!economy_mode || this.line_numbers != GESHI_NO_LINE_NUMBERS) && this.line_style1 != '') {
	            stylesheet += "{selector}li, {selector}.li1 {{this.line_style1}}\n";
	        }
	        if ((!economy_mode || this.line_numbers != GESHI_NO_LINE_NUMBERS) && this.table_linenumber_style != '') {
	            stylesheet += "{selector}.ln {{this.table_linenumber_style}}\n";
	        }
	        // If there is a style set for fancy line numbers, echo it out
	        if ((!economy_mode || this.line_numbers == GESHI_FANCY_LINE_NUMBERS) && this.line_style2 != '') {
	            stylesheet += "{selector}.li2 {{this.line_style2}}\n";
	        }
	
	        // note: empty styles are meaningless
	        //for each (this.language_data['STYLES']['KEYWORDS'] as group => styles) {
	        for (var group:* in this.language_data['STYLES']['KEYWORDS']) {
	        	var styles:* = this.language_data['STYLES']['KEYWORDS'][group];
	        	
	            if (styles != '' && (!economy_mode ||
	                (isset(this.lexic_permissions['KEYWORDS'][group]) &&
	                this.lexic_permissions['KEYWORDS'][group]))) {
	                stylesheet += "selector.kwgroup {{styles}}\n";
	            }
	        }
	        
	        //for each (this.language_data['STYLES']['COMMENTS'] as group => styles) {
	        for (group in this.language_data['STYLES']['COMMENTS']) {
	        	styles = this.language_data['STYLES']['COMMENTS'][group];
	        	
	            if (styles != '' && (!economy_mode ||
	                (isset(this.lexic_permissions['COMMENTS'][group]) &&
	                this.lexic_permissions['COMMENTS'][group]) ||
	                (!empty(this.language_data['COMMENT_REGEXP']) &&
	                !empty(this.language_data['COMMENT_REGEXP'][group])))) {
	                stylesheet += "selector.cogroup {{styles}}\n";
	            }
	        }
	        
	        //for each (this.language_data['STYLES']['ESCAPE_CHAR'] as group => styles) {
	        for (group in this.language_data['STYLES']['ESCAPE_CHAR']) {
	        	styles = this.language_data['STYLES']['ESCAPE_CHAR'][group];
	        	
	            if (styles != '' && (!economy_mode || this.lexic_permissions['ESCAPE_CHAR'])) {
	                // NEW: since 1.0.8 we have to handle hardescapes
	                if (group == 'HARD') {
	                    group = '_h';
	                }
	                stylesheet += "selector.esgroup {{styles}}\n";
	            }
	        }
	        
	        //for each (this.language_data['STYLES']['BRACKETS'] as group => styles) {
	        for (group in this.language_data['STYLES']['BRACKETS']) {
	        	styles = this.language_data['STYLES']['BRACKETS'][group];
	        	
	            if (styles != '' && (!economy_mode || this.lexic_permissions['BRACKETS'])) {
	                stylesheet += "selector.brgroup {{styles}}\n";
	            }
	        }
	        
	        //for each (this.language_data['STYLES']['SYMBOLS'] as group => styles) {
	        for (group in this.language_data['STYLES']['SYMBOLS']) {
	        	styles = this.language_data['STYLES']['SYMBOLS'][group];
	        	
	            if (styles != '' && (!economy_mode || this.lexic_permissions['SYMBOLS'])) {
	                stylesheet += "selector.sygroup {{styles}}\n";
	            }
	        }
	        
	        //for each (this.language_data['STYLES']['STRINGS'] as group => styles) {
	        for (group in this.language_data['STYLES']['STRINGS']) {
	        	styles = this.language_data['STYLES']['STRINGS'][group];
	        	
	            if (styles != '' && (!economy_mode || this.lexic_permissions['STRINGS'])) {
	                // NEW: since 1.0.8 we have to handle hardquotes
	                if (group === 'HARD') {
	                    group = '_h';
	                }
	                stylesheet += "selector.stgroup {{styles}}\n";
	            }
	        }
	        
	        //for each (this.language_data['STYLES']['NUMBERS'] as group => styles) {
	        for (group in this.language_data['STYLES']['NUMBERS']) {
	        	styles = this.language_data['STYLES']['NUMBERS'][group];
	        	
	            if (styles != '' && (!economy_mode || this.lexic_permissions['NUMBERS'])) {
	                stylesheet += "selector.nugroup {{styles}}\n";
	            }
	        }
	        
	        //for each (this.language_data['STYLES']['METHODS'] as group => styles) {
	        for (group in this.language_data['STYLES']['METHODS']) {
	        	styles = this.language_data['STYLES']['METHODS'][group];
	        	
	            if (styles != '' && (!economy_mode || this.lexic_permissions['METHODS'])) {
	                stylesheet += "selector.megroup {{styles}}\n";
	            }
	        }
	        
	        // note: neglect economy_mode, empty styles are meaningless
	        //for each (this.language_data['STYLES']['SCRIPT'] as group => styles) {
	        for (group in this.language_data['STYLES']['SCRIPT']) {
	        	styles = this.language_data['STYLES']['SCRIPT'][group];
	        	
	            if (styles != '') {
	                stylesheet += "selector.scgroup {{styles}}\n";
	            }
	        }
	        
	        //for each (this.language_data['STYLES']['REGEXPS'] as group => styles) {
	        for (group in this.language_data['STYLES']['REGEXPS']) {
	        	styles = this.language_data['STYLES']['REGEXPS'][group];
	        	
	            if (styles != '' && (!economy_mode ||
	                (isset(this.lexic_permissions['REGEXPS'][group]) &&
	                this.lexic_permissions['REGEXPS'][group]))) {
	                if (is_array(this.language_data['REGEXPS'][group]) &&
	                    array_key_exists(GESHI_CLASS, this.language_data['REGEXPS'][group])) {
	                    stylesheet += "selector.";
	                    stylesheet += this.language_data['REGEXPS'][group][GESHI_CLASS];
	                    stylesheet += " {{styles}}\n";
	                } else {
	                    stylesheet += "selector.regroup {{styles}}\n";
	                }
	            }
	        }
	        // Styles for lines being highlighted extra
	        if (!economy_mode || (count(this.highlight_extra_lines)!=count(this.highlight_extra_lines_styles))) {
	            stylesheet += "{selector}.ln-xtra, {selector}li.ln-xtra, {selector}div.ln-xtra {{this.highlight_extra_lines_style}}\n";
	        }
	        stylesheet += "{selector}span.xtra { display:block; }\n";
	        //for each (this.highlight_extra_lines_styles as lineid => linestyle) {
	        for (var lineid:* in this.highlight_extra_lines_styles) {
	        	var linestyle:* = this.highlight_extra_lines_styles[lineid];
	            stylesheet += "{selector}.lxlineid, {selector}li.lxlineid, {selector}div.lxlineid {{linestyle}}\n";
	        }
	
	        return stylesheet;
	    }
	
	    /**
	     * Get's the style that is used for the specified line
	     *
	     * @param int The line number information is requested for
	     * @access private
	     * @since 1.0.7.21
	     */
	    public function get_line_style(line:int):String {
	        //style = null;
	        var style:* = null;
	        if (isset(this.highlight_extra_lines_styles[line])) {
	            style = this.highlight_extra_lines_styles[line];
	        } else { // if no "extra" style assigned
	            style = this.highlight_extra_lines_style;
	        }
	
	        return style;
	    }
	
	    /**
	    * this functions creates an optimized regular expression list
	    * of an array of strings.
	    *
	    * Example:
	    * <code>list = array('faa', 'foo', 'foobar');
	    *          => string 'f(aa|oo(bar)?)'</code>
	    *
	    * @param list array of (unquoted) strings
	    * @param regexp_delimiter your regular expression delimiter, @see preg_quote()
	    * @return string for regular expression
	    * @author Milian Wolff <mail@milianw.de>
	    * @since 1.0.8
	    * @access private
	    */
	    public function optimize_regexp_list(list:Array, regexp_delimiter:String = '/'):String {
	        var regex_chars:* = array('.', '\\', '+', '*', '?', '[', '^', ']', '',
	            '(', ')', '{', '}', '=', '!', '<', '>', '|', ':', regexp_delimiter);
	        sort(list);
	        var regexp_list:* = array('');
	        var num_subpatterns:* = 0;
	        var list_key:* = 0;
			
	        // the tokens which we will use to generate the regexp list
	        var tokens:* = arrayObject();
	        var prev_keys:* = array();
	        // go through all entries of the list and generate the token list
	        for (var i:uint = 0, i_max:int = count(list); i < i_max; ++i) {
	            var level:* = 0;
	            var entry:* = preg_quote(String(list[i]), regexp_delimiter);
	            //pointer = &tokens;
	            var pointer:* = tokens;
	            // break out of the loops
	            var continue2:Boolean = false;
	            // properly assign the new entry to the correct position in the token array
	            // possibly generate smaller common denominator keys
	            while (true) {
	            	var keyValue:* = prev_keys[level];
	                // get the common denominator
	                if (isset(prev_keys[level])) {
	                    if (prev_keys[level] == entry) {
	                        // this is a duplicate entry, skip it
	                        continue2 = true;
	                        if (continue2) break;
	                    }
	                    var char:* = 0;
	                    /* while (isset(entry[char]) && isset(prev_keys[level][char])
	                            && entry[char] == prev_keys[level][char]) {
	                        ++char;
	                    } */
	                    while (isset(String(entry).charAt(char)) && isset(String(prev_keys[level]).charAt(char))
	                            && String(entry).charAt(char) == String(prev_keys[level]).charAt(char)) {
	                        ++char;
	                    }
	                    if (char > 0) {
	                        // this entry has at least some chars in common with the current key
	                        if (char == strlen(prev_keys[level])) {
	                            // current key is totally matched, i.e. this entry has just some bits appended
	                            //pointer = &pointer[prev_keys[level]];
	                            pointer = String(pointer[prev_keys[level]]);
	                        } else {
	                            // only part of the keys match
	                            var new_key_part1:* = substr(prev_keys[level], 0, char);
	                            var new_key_part2:* = substr(prev_keys[level], char);
	                            if (in_array(new_key_part1[0], regex_chars)
	                                || in_array(new_key_part2[0], regex_chars)) {
	                                // this is bad, a regex char as first character
	                                //pointer[entry] = array('' => true);
	                                pointer[entry] = {'': true};
	                                array_splice(prev_keys, level, count(prev_keys), entry);
	                                continue;
	                            } else {
	                                // relocate previous tokens
	                                //pointer[new_key_part1] = array(new_key_part2 => pointer[prev_keys[level]]);
	                                pointer[new_key_part1] = {new_key_part2: pointer[prev_keys[level]]};
	                                unset(pointer[prev_keys[level]]);
	                                //pointer = &pointer[new_key_part1];
	                                pointer = String(pointer[new_key_part1]);
	                                // recreate key index
	                                array_splice(prev_keys, level, count(prev_keys), array(new_key_part1, new_key_part2));
	                            }
	                        }
	                        ++level;
	                        entry = substr(entry, char);
	                        continue;
	                    }
	                    // else: fall trough, i.e. no common denominator was found
	                }
	                if (level == 0 && !empty(tokens)) {
	                    // we can dump current tokens into the string and throw them away afterwards
	                    var new_entry:* = this._optimize_regexp_list_tokens_to_string(tokens);
	                    var new_subpatterns:* = substr_count(new_entry, '(?:');
	                    if (GESHI_MAX_PCRE_SUBPATTERNS && num_subpatterns + new_subpatterns > GESHI_MAX_PCRE_SUBPATTERNS) {
	                        regexp_list[++list_key] = new_entry;
	                        num_subpatterns = new_subpatterns;
	                    } else {
	                        if (!empty(regexp_list[list_key])) {
	                            new_entry = '|' + new_entry;
	                        }
	                        regexp_list[list_key] += new_entry;
	                        num_subpatterns += new_subpatterns;
	                    }
	                    //tokens = array();
	                    tokens = arrayObject();
	                }
	                // no further common denominator found
	                //pointer[entry] = array('' => true);
	                if (entry == "hasOwnProperty" || entry == "isPrototypeOf" ||
	                	entry == "propertyIsEnumerable") {
		                pointer[entry+" "] = {'': true};
	                }
	                else {
		                pointer[entry] = {'': true};
	                }
	                array_splice(prev_keys, level, count(prev_keys), entry);
	                break;
	            }
	            
	            if (continue2) {
	            	continue2 = false;
	            	continue;
	            }
	            unset(list[i]);
	        }
	        // make sure the last tokens get converted as well
	        new_entry = this._optimize_regexp_list_tokens_to_string(tokens);
	        if (GESHI_MAX_PCRE_SUBPATTERNS && num_subpatterns + substr_count(new_entry, '(?:') > GESHI_MAX_PCRE_SUBPATTERNS) {
	            regexp_list[++list_key] = new_entry;
	        } else {
	            if (!empty(regexp_list[list_key])) {
	                new_entry = '|' + new_entry;
	            }
	            regexp_list[list_key] += new_entry;
	        }
	        return regexp_list;
	    }
	    /**
	    * this function creates the appropriate regexp string of an token array
	    * you should not call this function directly, @see this.optimize_regexp_list().
	    *
	    * @param &tokens array of tokens
	    * @param recursed bool to know wether we recursed or not
	    * @return string
	    * @author Milian Wolff <mail@milianw.de>
	    * @since 1.0.8
	    * @access private
	    */
	    public function _optimize_regexp_list_tokens_to_string(tokens:*, recursed:Boolean = false):String {
	        var list:* = '';
	        //for each (tokens as token => sub_tokens) {
	        for (var token:* in tokens) {
	        	var sub_tokens:* = tokens[token];
	            list += token;
	            // var close_entry:* = isset(sub_tokens['']); php
	            var close_entry:* = sub_tokens is Boolean;
	           //unset(sub_tokens['']); php
	           //unset(sub_tokens['']);
	            if (!empty(sub_tokens)) {
	                list += '(?:' + this._optimize_regexp_list_tokens_to_string(sub_tokens, true) + ')';
	                if (close_entry) {
	                    // make sub_tokens optional
	                    list += '?';
	                }
	            }
	            list += '|';
	        }
	        if (!recursed) {
	            // do some optimizations
	            // common trailing strings
	            // BUGGY!
	            //list = preg_replace_callback('#(?<=^|\:|\|)\w+?(\w+)(?:\|.+\1)+(?=\|)#', create_function(
	            //    'matches', 'return "(?:" + preg_replace("#" + preg_quote(matches[1], "#") + "(?=\||)#", "", matches[0]) + ")" + matches[1];'), list);
	            // (?:p)? => p?
	            list = preg_replace('#\(\?\:(.)\)\?#', '\1?', list);
	            // (?:a|b|c|d|...)? => [abcd...]?
	            // TODO: a|bb|c => [ac]|bb
	            //static callback_2;
	            var callback_2:*;
	            if (!isset(callback_2)) {
	                //callback_2 = create_function('matches', 'return "[" + str_replace("|", "", matches[1]) + "]";');
	                callback_2 = function (matches:Array):String {
	                	return "[" + str_replace("|", "", matches[1]) + "]";
	                }
	            }
	            list = preg_replace_callback('#\(\?\:((?:.\|)+.)\)#', callback_2, list);
	        }
	        // return list without trailing pipe
	        return substr(list, 0, -1);
	    }
	    
	    // Used for catching errors when loading language files
        private function configureListeners(dispatcher:IEventDispatcher):void {
            dispatcher.addEventListener(Event.COMPLETE, completeHandler);
            //dispatcher.addEventListener(Event.OPEN, openHandler);
            //dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
        }
        
        // put language data in the language data cache
        public function completeHandler(event:Event):void {
            var loader:URLLoader = URLLoader(event.target);
            trace("completeHandler: " + loader.data);
            
            // no data - maybe accessing the php file - bad - access the txt file 
            if (loader.data!=null) {
            	// this line will error out unless you use the as3corelib JSON class 
	    		var data:Object = JSON.parse(loader.data);
	    		var language:String = data.LANG_KEY;
	    		// replace constants with constants value
	    		data.STRICT_MODE_APPLIES = getConstantValue(data.STRICT_MODE_APPLIES);
	    		data.CASE_KEYWORDS = getConstantValue(data.CASE_KEYWORDS);
	    		this.language_cache[language] = data;
	    		loaded_language_length--;
	    		if (loaded_language_length==0) {
	    			dispatchEvent(new HighlightEvent(HighlightEvent.LOAD_COMPLETE));
	    			set_language(this.language);
	    		}
            }
    		
        }
        
        public function getConstantValue(constant:String):* {
        	if (SyntaxHighlighter[constant]) {
        		return SyntaxHighlighter[constant];
        	}
        	if (constant == "GESHI_CAPS_LOWER") {
        		return SyntaxHighlighter.GESHI_CAPS_LOWER;
        	}
        	else if (constant == "GESHI_CAPS_NO_CHANGE") {
        		return SyntaxHighlighter.GESHI_CAPS_NO_CHANGE;
        	}
        	else if (constant == "GESHI_CAPS_UPPER") {
        		return SyntaxHighlighter.GESHI_CAPS_UPPER;
        	}
        	else if (constant == "GESHI_NEVER") {
        		return SyntaxHighlighter.GESHI_NEVER;
        	}
        	else if (constant == "GESHI_MAYBE") {
        		return SyntaxHighlighter.GESHI_MAYBE;
        	}
        	return (constant!=null) ? constant : "";
        }

        private function openHandler(event:Event):void {
            trace("openHandler: " + event);
        }

        private function progressHandler(event:ProgressEvent):void {
            trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
        }

        private function securityErrorHandler(event:SecurityErrorEvent):void {
            trace("securityErrorHandler: " + event);
        }

        private function httpStatusHandler(event:HTTPStatusEvent):void {
            trace("httpStatusHandler: " + event);
        }

        private function ioErrorHandler(event:IOErrorEvent):void {
            trace("ioErrorHandler: " + event);
        }

	
	//if (!function_exists('geshi_highlight')) {
	//    /**
	//     * Easy way to highlight stuff. Behaves just like highlight_string
	//     *
	//     * @param string The code to highlight
	//     * @param string The language to highlight the code in
	//     * @param string The path to the language files. You can leave this blank if you need
	//     *               as from version 1.0.7 the path should be automatically detected
	//     * @param boolean Whether to return the result or to echo
	//     * @return string The code highlighted (if return is true)
	//     * @since 1.0.2
	//     */
	//    function geshi_highlight(string, language, path = null, return = false) {
	//        geshi = new GeSHi(string, language, path);
	//        geshi->set_header_type(GESHI_HEADER_NONE);
	//
	//        if (return) {
	//            return '<code>' + geshi->parse_code() + '</code>';
	//        }
	//
	//        echo '<code>' + geshi->parse_code() + '</code>';
	//
	//        if (geshi->get_error()) {
	//            return false;
	//        }
	//        return true;
	//    }
	//}
	
	/*********************** PHP FUNCTIONS ***************************/
	
	/** 
	 * HOW SHOULD THESE FUNCTIONS HANDLE ERRORS
	 * We should put them in their own namespace
	 * @author - Judah Frangipane (when the code works)
	 * Reference - http://kerkness.blogspot.com/search/label/php-to-flex
	 * Reference - http://kevin.vanzonneveld.net/code/php_equivalents/php.js
	 ***/

	/*
	NOTES - CONVERTING PHP TO AS3
	
	
	 * You can learn how to convert a PHP "for each" loop to AS3 using the example below: 	
	        
	PHP:
	for each (this.lexic_permissions as key => value) {
	    if (is_array(value)) {
	        for each (value as k => v) {
	            this.lexic_permissions[key][k] = flag;
	        }
	    } else {
	        this.lexic_permissions[key] = flag;
	    }
	}
	
	AS3: 
	for (var key:* in this.lexic_permissions) {
		var value:* = this.lexic_permissions[key];
	    if (is_array(value)) {
	        for (var k in value) {
	            this.lexic_permissions[key][k] = flag;
	        }
	    } else {
	        this.lexic_permissions[key] = flag;
	    }
	}
	
	
	
	 * You can convert associative arrays to objects by learning from this example:
	
	PHP:
	numbers_format = array(
		                GESHI_NUMBER_INT_BASIC =>
		                    '(?<![0-9a-z_\.%])(?<![\d\.]e[+\-])[1-9]\d*?(?![0-9a-z\.])',
		                GESHI_NUMBER_INT_CSTYLE =>
		                    '(?<![0-9a-z_\.%])(?<![\d\.]e[+\-])[1-9]\d*?l(?![0-9a-z\.])');
	
	AS3:
	numbers_format = {
		                propertyName:'value',
		                propertyName2:'value'
		                }
	
	
	
	 * You must remove the brackets [] in array assignments:
	
	
	PHP:
	symbol_preg_multi[] = preg_quote(sym, '/');
	
	AS3:
	var symbol_preg_multi:Array = preg_quote(sym, '/');
	
	
	
	 * You must remove the last comma in array lists:
	
	this.language_data['CACHE_BRACKET_REPLACE'] = array(
		                    '<| class="br0">&#91;|>',
		                    '<| class="br0">&#125;|>', <------ REMOVE THIS COMMA
		                );
	
	 * Remove static before variables declared within functions   
	
	Incorrect:
	function method() {
		static numbers_format
	}
	
	Correct: 
	function method() {
		static numbers_format
	}
	*/
	
	
	//////////////////////////// CONSTANTS ////////////////////////////
	
	// Array sort - compare items normally (don't change types)
	public static const SORT_REGULAR:int = 0;
	// Array sort - compare items numerically
	public static const SORT_NUMERIC:int = 1;
	// Array sort - compare items as strings
    public static const SORT_STRING:int = 2;
    // Array sort - compare items as strings, based on the current locale. 
	public static const SORT_LOCALE_STRING:int = 5;

	
	// Specifies how to encode single and double quotes.
	// Default. Will convert double-quotes and leave single-quotes alone.
	// http://www.w3schools.com/PHP/func_string_htmlentities.asp
	public static const ENT_COMPAT:int = 2;
	
	// Specifies how to encode single and double quotes.
	// Will convert both double and single quotes.
	// http://www.w3schools.com/PHP/func_string_htmlentities.asp
	public static const ENT_QUOTES:int = 3;
	
	// Specifies how to encode single and double quotes.
	// Will leave both double and single quotes unconverted.
	// http://www.w3schools.com/PHP/func_string_htmlentities.asp
	public static const ENT_NOQUOTES:int = 0;
	
	//////////////////////////// ARRAY FUNCTIONS ////////////////////////////

	// Creates an array
	// [ mixed $...]
	// http://us.php.net/manual/en/function.array.php
	public function array(...args):Array {
		return new Array(args);
	}

	// Creates an associative array
	// [ mixed $...]
	// http://us.php.net/manual/en/function.array.php
	public function arrayObject(...args):Object {
		var newObject:Object = new Object();
		for (var item:* in args) {
			newObject[item] = args[item];
		}
		return newObject;
	}
	
	// Checks if the given key or index exists in the array
	// returns TRUE if the given key is set in the array. key can be any value possible for an array index. 
	// mixed $key, array $search
	// http://us2.php.net/manual/en/function.array-key-exists.php
	public function array_key_exists(key:*, search:*):Boolean {
		
		for (var item:* in search) {
			if (item==key) {
				return true;
			}
		}
		return false;
	}

	// Return all the keys of an array
	// array $input  [, mixed $search_value  [, bool $strict  ]]
	// http://us3.php.net/manual/en/function.array-keys.php
	public function array_keys(input:*, search_value:String = "", strict:Boolean = false):Array {
		var array:Array = [];
		for (var key:* in input) {
			if (search_value!="" && search_value!=null) {
				if (strict) {
					if (search_value===key) {
						array.push(key);
					}
				}
				else {
					if (search_value==key) {
						array.push(key);
					}
				}
			}
			else {
				array.push(key);
			}
		}
		return array;
	}
	
	// Push one or more elements onto the end of array
	// array &$array  , mixed $var  [, mixed $...  ]
	// http://us.php.net/manual/en/function.array-push.php
	public function array_push(array:Array, ...args):int {
		for (var i:int = 0; i<args.length; i++) {
			array.push(args[i]);
		}
		return array.length;
	}
	
	// Searches the array for a given value and returns the corresponding key if successful
	// mixed $needle  , array $haystack  [, bool $strict  ] 
	// http://www.php.net/manual/en/function.array-search.php
	public function array_search(needle:*, haystack:Array, strict:Boolean = false):* {
		var array:Array = [];
		for (var key:String in haystack) {
			var value:* = haystack[key];
			if (strict) {
				if (needle===value) {
					return key;
				}
			}
			else {
				if (needle==value) {
					return key;
				}
			}
		}
		return false;
	}
	
	// Removes the elements designated by offset and length from the input array, 
	// and replaces them with the elements of the replacement array, if supplied. 
	// array &$input  , int $offset  [, int $length  [, mixed $replacement  ]]
	// http://us.php.net/manual/en/function.array-splice.php
	public function array_splice(array:Array, offset:int, length:int = 0, replacement:* = null):* {
	    var checkToUpIndices:Function = function (array:*, ct:int, key:*):int {
	        // Deal with situation, e.g., if encounter index 4 and try to set it to 0, but 0 exists later in loop (need to
	        // increment all subsequent (skipping current key, since we need its value below) until find unused)
	        if (array[ct] !== undefined) {
	            var tmp:int = ct;
	            ct += 1;
	            if (ct === key) {
	                ct += 1;
	            }
	            ct = checkToUpIndices(array, ct, key);
	            array[ct] = array[tmp];
	            delete array[tmp];
	        }
	        return ct;
	    }
	
	    if (replacement && !(typeof replacement === 'object')) {
	        replacement = [replacement];
	    }
	    if (length === 0) {
	        length = offset >= 0 ? array.length - offset : -offset;
	    } else if (length < 0) {
	        length = (offset >= 0 ? array.length - offset : -offset)  + length;
	    }
	
	    if (!(array is Array)) {
	        /*if (arr.length !== undefined) { // Deal with array-like objects as input
	        delete arr.length;
	        }*/
	        var lgt:int = 0, ct:int = -1, rmvd:Array = [], rmvdObj:* = {}, repl_ct:int=-1, int_ct:int=-1;
	        var returnArr:Boolean = true, rmvd_ct:int = 0, rmvd_lgth:int = 0, key:* = '';
	        // rmvdObj.length = 0;
	        for (key in array) { // Can do arr.__count__ in some browsers
	            lgt += 1;
	        }
	        offset = (offset >= 0) ? offset : lgt + offset;
	        for (key in array) {
	            ct += 1;
	            if (ct < offset) {
	                if (key is int) {
	                    int_ct += 1;
	                    if (parseInt(key, 10) === int_ct) { // Key is already numbered ok, so don't need to change key for value
	                        continue;
	                    }
	                    checkToUpIndices(array, int_ct, key); // Deal with situation, e.g.,
	                    // if encounter index 4 and try to set it to 0, but 0 exists later in loop
	                    array[int_ct] = array[key];
	                    delete array[key];
	                }
	                continue;
	            }
	            if (returnArr && key is int) {
	                rmvd.push(array[key]);
	                rmvdObj[rmvd_ct++] = array[key]; // PHP starts over here too
	            } else {
	                rmvdObj[key] = array[key];
	                returnArr    = false;
	            }
	            rmvd_lgth += 1;
	            // rmvdObj.length += 1;
	
	            if (replacement && replacement[++repl_ct]) {
	                array[key] = replacement[repl_ct]
	            } else {
	                delete array[key];
	            }
	        }
	        // arr.length = lgt - rmvd_lgth + (replacement ? replacement.length : 0); // Make (back) into an array-like object
	        return returnArr ? rmvd : rmvdObj;
	    }
	
	    if (replacement) {
	        replacement.unshift(offset, length);
	        return Array.prototype.splice.apply(array, replacement);
	    }
	    return array.splice(offset, length);

	}
	
	// Count elements in an array, or properties in an object
	// mixed $var  [, int $mode  ]
	// http://www.php.net/manual/en/function.count.php
	// AS3 - Array(array).length;
	public function count(mixed_var:*, mode:* = 0):int {
	    var key:*, cnt:int = 0;
	
	    if( mode == 'COUNT_RECURSIVE' ) mode = 1;
	    if( mode != 1 ) mode = 0;
	
	    for (key in mixed_var){
	        cnt++;
	        if( mode==1 && mixed_var[key] && (mixed_var[key] is Array || mixed_var[key] is Object) ){
	            cnt += count(mixed_var[key], 1);
	        }
	    }
	    
    	return cnt;

	}
	
	// Checks if a value exists in an array
	// mixed $needle, array $haystack  [, bool $strict  ]
	// http://www.php.net/manual/en/function.in-array.php
	public function in_array(needle:*, haystack:*, strict:Boolean = false):Boolean {
		for (var key:String in haystack) {
			var value:* = haystack[key];
			if (strict) {
				if (needle===value) {
					return true;
				}
			}
			else {
				if (needle==value) {
					return true;
				}
			}
		}
		return false;
	}
	
	// Finds whether a variable is an array
	// mixed $var
	// http://us.php.net/manual/en/function.is-array.php
	public function is_array(variable:*):Boolean {
		return (variable is Object || variable is Array);
	}
	
	// This function sorts an array. Elements will be arranged from lowest to highest when this function has completed. 
	// array &$array  [, int $sort_flags  ]
	// http://us.php.net/manual/en/function.sort.php
	public function sort(array:Array, sort_flags:int=0):Array {
		return array.sort();
	}
	
	//////////////////////////// DATE / TIME FUNCTIONS ////////////////////////////
	
	// Return current Unix timestamp with microseconds
	// [ bool $get_as_float  ]
	// http://us3.php.net/manual/en/function.microtime.php
	public function microtime(get_as_float:Boolean = false):* {
		if (get_as_float) {
			return Number(getTimer());
		}
		return getTimer();
	}
	
	//////////////////////////// ERROR HANDLING FUNCTIONS ////////////////////////////
	
	// The designated error type for this error. It only works with the E_USER family of
	// constants, and will default to E_USER_NOTICE
	// NOTE - value not verified
	public static const E_USER_WARNING:int = 0;
	
	// Generates a user-level error/warning/notice message
	// string $error_msg  [, int $error_type  ]
	// http://us.php.net/manual/en/function.trigger-error.php
	public function trigger_error(error_msg:String, error_type:int = 0):Boolean {
		trace(error_msg);
		return false;
	}
	
	//////////////////////////// FILE SYSTEM FUNCTIONS ////////////////////////////
	
	// Reads entire file into a string
	// string $filename  [, int $flags  [, resource $context  [, int $offset  [, int $maxlen  ]]]]
	// http://www.php.net/manual/en/function.file-get-contents.php
	// AS3 - 
	public function file_get_contents(filename:String):String {
		return filename;
	}
	
	// Tells whether the filename is readable
	// http://www.php.net/manual/en/function.is-readable.php
	public function is_readable(filename:String):Boolean {
		// we are returning true all the time
		return true;
	}
	
	//////////////////////////// FUNCTION HANDLING FUNCTIONS ////////////////////////////
	
	// Call a user function given by the first parameter
	// callback $function  [, mixed $parameter  [, mixed $...  ]]
	// http://us3.php.net/manual/en/function.call-user-func.php
	public function call_user_func(callback:*, ...args):void {
		Function(callback).apply(this, args);
	}
	
	// Creates an anonymous function from the parameters passed, and returns a unique name for it.
	// string $args  , string $code 
	// http://us.php.net/manual/en/function.create-function.php
	public function create_function(args:String, code:String):* {
		return;
	}
	
	// Returns an array comprising a function's argument list
	// USE the local variable "arguments" 
	// http://us.php.net/manual/en/function.func-get-args.php
	public function func_get_args():Array {
		return new Array();
	}
	
	// Return TRUE if the given function has been defined
	// string $function_name
	// http://us.php.net/manual/en/function.function-exists.php
	public function function_exists(name:String):Boolean {
		// might want to use describeType on the class and check for the method name that way
		var methodExists:Boolean = Object(this).hasOwnProperty(name);
		
		return methodExists; 
	}
	
	//////////////////////////// MATH FUNCTIONS ////////////////////////////
	
	// Returns the absolute value of a number
	// mixed $number
	// http://www.php.net/manual/en/function.abs.php
	public function abs(number:*):Number {
		return Math.abs(number);
	}
	
	//////////////////////////// MULTIBYTE FUNCTIONS ////////////////////////////
	
	// Performs a multi-byte safe substr() operation based on number of characters. Position is 
	// counted from the beginning of str . First character's position is 0. Second character 
	// position is 1, and so on. 
	// string $str  , int $start  [, int $length  [, string $encoding  ]]
	// http://us3.php.net/manual/en/function.mb-substr.php
	public function mb_substr(string:String, start:int, length:int = 0, encoding:String = ""):String {
		if (length!=0) {
			string = String(string).substr(start, length);
			return string;
		}
		return String(string).substr(start);
	}
	
	//////////////////////////// PERL COMPATIBLE REGULAR EXPRESSIONS ////////////////////////////
	
	// Orders results so that $matches[0] is an array of full pattern matches, $matches[1] is an 
	// array of strings matched by the first parenthesized subpattern, and so on.
	// NOTE - value not verified
	public static const PREG_PATTERN_ORDER:int = 1;
	
	// Orders results so that $matches[0] is an array of first set of matches, $matches[1] is 
	// an array of second set of matches, and so on. 
	// NOTE - value not verified
	public static const PREG_SET_ORDER:int = 2;
	
	// If this flag is passed, for every occurring match the appendant string offset will also be 
	// returned. Note that this changes the return value in an array where every element is an 
	// array consisting of the matched string at index 0 and its string offset into subject at index 1.
	// NOTE - value not verified
	public static const PREG_OFFSET_CAPTURE:int = 256;
	
	// Searches subject for all matches to the regular expression given in pattern and puts them 
	// in matches in the order specified by flags . 
	// string $pattern  , string $subject  , array &$matches  [, int $flags  [, int $offset  ]]
	// http://us.php.net/manual/en/function.preg-match-all.php
	// http://faces.jp/2008/03/as3regexp_preg_match_all.html
	public function preg_match_all(pattern:String, subject:String, matches:Array, flags:* = 0, offset:* = 0):* {
		matches.splice(0);
		
		var a:* = explode("/", pattern);
		var option:* = a.pop();
		
		a.shift();
		
		var r:RegExp = new RegExp(implode("/", a), option);
		var reg:* = r.exec(subject);
		
		while (reg != null) {
			//trace( reg.index, "\t", reg);
			matches.push(reg);
			reg = r.exec(subject);
		}
		
		return (count(matches));

	}
	
	// Searches subject for a match to the regular expression given in pattern
	// string $pattern  , string $subject  [, array &$matches  [, int $flags  [, int $offset  ]]]
	// http://us.php.net/manual/en/function.preg-match.php
	// AS3 - String(string).match(pattern);
	public function preg_match(pattern:*, subject:String, matches:* = null, flags:* = 0, offset:* = 0):* {
		var matches1:Array = new Array();
		
		matches1 = String(subject).match(pattern);
		
		if (matches!=null) {
			matches = matches1;
		}
		
		return matches1;
	}
	
	// Quote regular expression characters
	// string $str  [, string $delimiter  ]
	// http://www.php.net/manual/en/function.preg-quote.php
	// AS3 - 
	// http://kevin.vanzonneveld.net/code/php_equivalents/php.js
	public function preg_quote(string:String, delimiter:String = "\\"):* {
		return string.replace(/([\\\.\+\*\?\[\^\]\$\(\)\{\}\=\!\<\>\|\:])/g, "\\$1");
	}
	
	// Perform a regular expression search and replace using a callback
	// mixed $pattern  , callback $callback  , mixed $subject  [, int $limit  [, int &$count  ]]
	// http://us.php.net/manual/en/function.preg-replace-callback.php
	public function preg_replace_callback(pattern:*, callback:*, subject:*, limit:int = -1, count:int = 0):* {
		return subject.replace(RegExp(pattern), function():* {return callback(arguments);});
	}
	  
	// Perform a regular expression search and replace
	// Searches subject for matches to pattern and replaces them with replacement 
	// mixed $pattern  , mixed $replacement  , mixed $subject  [, int $limit  [, int &$count  ]]
	// http://www.php.net/manual/en/function.preg-replace.php
	// NOTES - needs validating and support for limit and count
	public function preg_replace(pattern:*, replacement:*, subject:*, limit:int = -1, count:int = 0):String {
		var patternValue:* = "";
		var replacementValue:* = "";
		var replacementIsArray:Boolean = (replacement is Array);
		var subjectIsArray:Boolean = (subject is Array);
			
		if (pattern is Array) {
			var patternLength:int = pattern.length;
			var subjectLength:int = (subjectIsArray) ? subject.length : 0;
			
			// loop through and replace values
			// pattern and replacement lengths should match - right?
			for (var i:int=0; i < patternLength; i++) {
				patternValue = pattern[i];
				replacementValue = (replacementIsArray) ? replacement[i] : replacement;
				
				if (subjectIsArray) {
					for (var j:int=0; j < subjectLength; j++) {
						var subjectItem:String = subject[j];
						subjectItem = String(subjectItem).replace(patternValue, replacementValue);
					}
				}
				else {
					subject = String(subject).replace(patternValue, replacementValue);
				}
			}
		}
		else {
			if (subjectIsArray) {
				for (j=0; j < subjectLength; j++) {
					subjectItem = subject[j];
					subjectItem = String(subjectItem).replace(pattern, replacement);
				}
			}
			else {
				subject = String(subject).replace(pattern, replacement);
			}
		}
		
		return subject;
	}
	
	
	//////////////////////////// STRING FUNCTIONS ////////////////////////////
	
	// Split a string by string
	// string $delimiter  , string $string  [, int $limit  ]
	// http://www.php.net/manual/en/function.explode.php
	// AS3 - String(string).split(delimiter);
	public function explode(delimiter:String, string:String, limit:int = 0):Array {
		return String(string).split(delimiter);
	}
	
	// Join array elements with a string
	// string $glue  , array $pieces
	// http://us.php.net/manual/en/function.implode.php
	// AS3 - Array(array).join(delimiter);
	public function implode(glue:*, array:* = null):String {
		
		return String( ( array is Array ) ? array.join ( glue ) : array );
	}
	
	// Calculates the MD5 hash of string and returns that hash. 
	// string $str  [, bool $raw_output  ] 
	// http://us.php.net/manual/en/function.md5.php
	public function md5(string:String, raw_output:Boolean = false):String {
		return string;
	}
	
	// Inserts HTML line breaks before all newlines in a string
	// string $string  [, bool $is_xhtml  ]
	// http://us3.php.net/manual/en/function.nl2br.php
	public function nl2br(string:String, is_xhtml:Boolean = true):String {
		var br:String = (is_xhtml) ? "<br />" : "<br>";
		return String(string).replace("/\\r\\n|\\n|\\r/", br);
	}
	
	// Format a number with grouped thousands
	// float $number  , int $decimals  , string $dec_point  , string $thousands_sep
	// http://us.php.net/manual/en/function.number-format.php
	// http://www.sephiroth.it/proto_detail.php?id=54
	public function number_format(number:Number, decimals:uint, dec_point:String = ".", thousands_sep:String = ","):String {
		var num:String = Number(number).toFixed(decimals);
		var length:int = String(num).length;
		
		for (var i:int=0; i < length;i++) {
			// 
		}
		return num;
	}
	
	// Returns the ASCII value of the first character of string
	// string $string
	// http://us3.php.net/manual/en/function.ord.php
	// AS3 - ??
	public function ord(string:String):int {
		return String(string).charCodeAt(0);
	}
	
	// Returns a string produced according to the formatting string format 
	// string $format  [, mixed $args  [, mixed $...  ]
	// http://us.php.net/manual/en/function.sprintf.php
	// 
	/**  sprintf(3) implementation in ActionScript 3.0.
	 *
	 *  Author:  Manish Jethani (manish.jethani@gmail.com)
	 *  Date:    April 3, 2006
	 *  Version: 0.1
	 *
	 *  Copyright (c) 2006 Manish Jethani
	 *
	 *  Permission is hereby granted, free of charge, to any person obtaining a
	 *  copy of this software and associated documentation files (the "Software"),
	 *  to deal in the Software without restriction, including without limitation
	 *  the rights to use, copy, modify, merge, publish, distribute, sublicense,
	 *  and/or sell copies of the Software, and to permit persons to whom the
	 *  Software is furnished to do so, subject to the following conditions:
	 *
	 *  The above copyright notice and this permission notice shall be included in
	 *  all copies or substantial portions of the Software.
	 *
	 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	 *  DEALINGS IN THE SOFTWARE.  
	 *
	 *  ---
	 * 
	 *  sprintf(3) implementation in ActionScript 3.0.
	 *
	 *  http://www.die.net/doc/linux/man/man3/sprintf.3.html
	 *
	 *  The following flags are supported: '#', '0', '-', '+'
	 *
	 *  Field widths are fully supported.  '*' is not supported.
	 *
	 *  Precision is supported except one difference from the standard: for an
	 *  explicit precision of 0 and a result string of "0", the output is "0"
	 *  instead of an empty string.
	 *
	 *  Length modifiers are not supported.
	 *
	 *  The following conversion specifiers are supported: 'd', 'i', 'o', 'u', 'x',
	 *  'X', 'f', 'F', 'c', 's', '%'
	 *
	 *  Report bugs to manish.jethani@gmail.com
	 * 
	 **/
	public function sprintf(format:String, ... args):String {
		var result:String = "";
	
		var length:int = format.length;
		for (var i:int = 0; i < length; i++) {
			var c:String = format.charAt(i);
	
			if (c == "%") {
				var pastFieldWidth:Boolean = false;
				var pastFlags:Boolean = false;
	
				var flagAlternateForm:Boolean = false;
				var flagZeroPad:Boolean = false;
				var flagLeftJustify:Boolean = false;
				var flagSpace:Boolean = false;
				var flagSign:Boolean = false;
	
				var fieldWidth:String = "";
				var precision:String = "";
	
				c = format.charAt(++i);
	
				while (c != "d"
					&& c != "i"
					&& c != "o"
					&& c != "u"
					&& c != "x"
					&& c != "X"
					&& c != "f"
					&& c != "F"
					&& c != "c"
					&& c != "s"
					&& c != "%")
				{
					if (!pastFlags)
					{
						if (!flagAlternateForm && c == "#")
							flagAlternateForm = true;
						else if (!flagZeroPad && c == "0")
							flagZeroPad = true;
						else if (!flagLeftJustify && c == "-")
							flagLeftJustify = true;
						else if (!flagSpace && c == " ")
							flagSpace = true;
						else if (!flagSign && c == "+")
							flagSign = true;
						else
							pastFlags = true;
					}
	
					if (!pastFieldWidth && c == ".")
					{
						pastFlags = true;
						pastFieldWidth = true;
	
						c = format.charAt(++i);
						continue;
					}
	
					if (pastFlags)
					{
						if (!pastFieldWidth)
							fieldWidth += c;
						else
							precision += c;
					}
	
					c = format.charAt(++i);
				}
	
				switch (c)
				{
				case "d":
				case "i":
					var next:* = args.shift();
					var str:String = String(Math.abs(int(next)));
	
					if (precision != "")
						str = sprintf_leftPad(str, int(precision), "0");
	
					if (int(next) < 0)
						str = "-" + str;
					else if (flagSign && int(next) >= 0)
						str = "+" + str;
	
					if (fieldWidth != "")
					{
						if (flagLeftJustify)
							str = sprintf_rightPad(str, int(fieldWidth));
						else if (flagZeroPad && precision == "")
							str = sprintf_leftPad(str, int(fieldWidth), "0");
						else
							str = sprintf_leftPad(str, int(fieldWidth));
					}
	
					result += str;
					break;
	
				case "o":
					next = args.shift();
					str = uint(next).toString(8);
	
					if (flagAlternateForm && str != "0")
						str = "0" + str;
	
					if (precision != "")
						str = sprintf_leftPad(str, int(precision), "0");
	
					if (fieldWidth != "")
					{
						if (flagLeftJustify)
							str = sprintf_rightPad(str, int(fieldWidth));
						else if (flagZeroPad && precision == "")
							str = sprintf_leftPad(str, int(fieldWidth), "0");
						else
							str = sprintf_leftPad(str, int(fieldWidth));
					}
	
					result += str;
					break;
	
				case "u":
					next = args.shift();
					str = uint(next).toString(10);
	
					if (precision != "")
						str = sprintf_leftPad(str, int(precision), "0");
	
					if (fieldWidth != "")
					{
						if (flagLeftJustify)
							str = sprintf_rightPad(str, int(fieldWidth));
						else if (flagZeroPad && precision == "")
							str = sprintf_leftPad(str, int(fieldWidth), "0");
						else
							str = sprintf_leftPad(str, int(fieldWidth));
					}
	
					result += str;
					break;
	
				case "X":
					var capitalise:Boolean = true;
				case "x":
					next = args.shift();
					str = uint(next).toString(16);
	
					if (precision != "")
						str = sprintf_leftPad(str, int(precision), "0");
	
					var prepend:Boolean = flagAlternateForm && uint(next) != 0;
	
					if (fieldWidth != "" && !flagLeftJustify
							&& flagZeroPad && precision == "")
						str = sprintf_leftPad(str, prepend
								? int(fieldWidth) - 2 : int(fieldWidth), "0");
	
					if (prepend)
						str = "0x" + str;
	
					if (fieldWidth != "")
					{
						if (flagLeftJustify)
							str = sprintf_rightPad(str, int(fieldWidth));
						else
							str = sprintf_leftPad(str, int(fieldWidth));
					}
	
					if (capitalise)
						str = str.toUpperCase();
	
					result += str;
					break;
	
				case "f":
				case "F":
					next = args.shift();
					str = Math.abs(Number(next)).toFixed(
							precision != "" ?  int(precision) : 6);
	
					if (int(next) < 0)
						str = "-" + str;
					else if (flagSign && int(next) >= 0)
						str = "+" + str;
	
					if (flagAlternateForm && str.indexOf(".") == -1)
						str += ".";
	
					if (fieldWidth != "")
					{
						if (flagLeftJustify)
							str = sprintf_rightPad(str, int(fieldWidth));
						else if (flagZeroPad && precision == "")
							str = sprintf_leftPad(str, int(fieldWidth), "0");
						else
							str = sprintf_leftPad(str, int(fieldWidth));
					}
	
					result += str;
					break;
	
				case "c":
					next = args.shift();
					str = String.fromCharCode(int(next));
	
					if (fieldWidth != "")
					{
						if (flagLeftJustify)
							str = sprintf_rightPad(str, int(fieldWidth));
						else
							str = sprintf_leftPad(str, int(fieldWidth));
					}
	
					result += str;
					break;
	
				case "s":
					next = args.shift();
					str = String(next);
	
					if (precision != "")
						str = str.substring(0, int(precision));
	
					if (fieldWidth != "")
					{
						if (flagLeftJustify)
							str = sprintf_rightPad(str, int(fieldWidth));
						else
							str = sprintf_leftPad(str, int(fieldWidth));
					}
	
					result += str;
					break;
	
				case "%":
					result += "%";
				}
			}
			else
			{
				result += c;
			}
		}
	
		return result;
	}


	// Private functions
	public function sprintf_leftPad(source:String, targetLength:int, padChar:String = " "):String {
		if (source.length < targetLength) {
			var padding:String = "";
	
			while (padding.length + source.length < targetLength)
				padding += padChar;
	
			return padding + source;
		}
	
		return source;
	}

	public function sprintf_rightPad(source:String, targetLength:int, padChar:String = " "):String {
		while (source.length < targetLength)
			source += padChar;
	
		return source;
	}
	
	// Returns input repeated multiplier times. 
	// string $input, int $multiplier
	// http://us3.php.net/manual/en/function.str-repeat.php
	public function str_repeat(input:String, multiplier:int):String {
		var string:String = "";
		for(var i:int=0; i < multiplier; i++) {
			string += input;
	  	}
		return string;
	}

	// Replace all occurrences of the search string with the replacement string
	// mixed $search, mixed $replace, mixed $subject [, int &$count  ]
	// http://www.php.net/manual/en/function.str-replace.php
	// AS3 - String(string).replace(pattern, replacement);
	public function str_replace(search:*, replace:*, subject:*, count:int = 0):String {
		var value:String = subject.replace(search, replace);
		return value;
	}
	
	// Binary safe case-insensitive string comparison
	// string $str1  , string $str2
	// http://us3.php.net/manual/en/function.strcasecmp.php
	public function strcasecmp(string1:String, string2:String):int {
		if (String(string1).toLowerCase()==String(string2).toLowerCase()) {
			return 0;
		}
		if (String(string1).toLowerCase()<String(string2).toLowerCase()) {
			return -1;
		}
		if (String(string1).toLowerCase()>String(string2).toLowerCase()) {
			return 1;
		}
		return -1;
	}
	
	// Returns the length of the given string
	// http://us3.php.net/manual/en/function.strlen.php
	// AS3 - String(string).length;
	public function strlen(string:String = ""):int {
		return string.length;
	}
	
	// Returns the numeric position of the first occurrence of needle in the haystack string. 
	// Unlike strpos(), stripos() is case-insensitive. 
	// string $haystack  , string $needle  [, int $offset  ]
	// http://us3.php.net/manual/en/function.stripos.php
	public function stripos(haystack:String = "", needle:String = "", offset:int = 0):* {
	    haystack = (haystack+'').toLowerCase();
	    needle = (needle+'').toLowerCase();
	    var index:int = 0;
	 
	    if ((index = haystack.indexOf(needle, offset)) !== -1) {
	        return index;
	    }
	    return false;

		
	}
	
	// Find position of first occurrence of a string
	// string $haystack  , mixed $needle  [, int $offset  ]
	// http://us.php.net/manual/en/function.strpos.php
	// AS3 - String(haystack).indexOf(needle, offset);
	public function strpos(haystack:String, needle:*, offset:int = 0):* {
		var position:int = String(haystack).indexOf(needle, offset);
		
		return (position==-1) ? false : position;
	}
	
	// This function returns the portion of string, or FALSE if needle is not found. 
	// http://www.php.net/manual/en/function.strrchr.php
	// AS3 - 
	public function strrchr(haystack:String, needle:*):* {
		var position:int = String(haystack).lastIndexOf(needle);
		if (position!=-1) {
			haystack = haystack.substr(position);
			return haystack;
		}
		return false;
	}
	
	// Make a string lowercase
	// http://www.php.net/manual/en/function.strtolower.php
	// AS3 - String(string).toLowerCase();
	public function strtolower(string:String):String {
		return string.toLowerCase();
	}
	
	// Make a string uppercase
	// http://www.php.net/manual/en/function.strtoupper.php
	// AS3 - String(string).toUpperCase();
	public function strtoupper(string:String):String {
		return string.toUpperCase();
	}
	
	// This function returns a copy of str, translating all occurrences of each character in 
	// from to the corresponding character in toValue . 
	// string $str  , string $from  , string $to
	// http://us2.php.net/manual/en/function.strtr.php
	public function strtr(string:String = "", from:* = "", toValue:String = ""):String {
		var fromString:String = "";
		var length:int = 0;
	
	    if (typeof from === 'object') {
	    	if (string!=null) {
		        for (fromString in from) {
		        	var replacement:String = from[fromString];
		            string = string.replace(fromString, replacement);
		        }
		        return string;
		    }
	        return "";
	    }
	    
	    length = toValue.length;
	    if (from.length < toValue.length) {
	        length = from.length;
	    }
	    for (var i:int = 0; i < length; i++) {
	        string = string.replace(from[i], toValue[i]);
	    }
	    
	    return string;

	}
	
	// Returns the number of times the needle substring occurs in the haystack string. 
	// Please note that needle is case sensitive. 
	// string $haystack  , string $needle  [, int $offset  [, int $length  ]]
	// http://us.php.net/manual/en/function.substr-count.php
	// http://kevin.vanzonneveld.net
    // +   original by: Kevin van Zonneveld (http://kevin.vanzonneveld.net)
    // +   bugfixed by: Onno Marsman
	public function substr_count(haystack:String, needle:String, offset:int = 0, length:int = 0):* {
		length = (length!=0) ? length : haystack.length;
		var string:String = (offset>0) ? haystack.substr(offset, length) : haystack;
		var position:int = 0;
		var count:int = 0;
 
	    offset--;

	    while( (offset = haystack.indexOf(needle, offset+1)) != -1 ){
	        if(length > 0 && (offset+needle.length) > length){
	            return false;
	        } else{
	            count++;
	        }
	    }
	 
	    return count;
	}
	
	// Replace a copy of string delimited by the start and (optionally) length parameters
	// with the string given in replacement
	// mixed $string  , string $replacement  , int $start  [, int $length  ]
	// http://us2.php.net/manual/en/function.substr-replace.php
	public function substr_replace(string:*, replacement:*, start:int, length:int = 0):String {
		var startString:String = String(string).substr(0, start);
		var replaceString:String = (length!=0) ? String(string).substr(start, length) : String(string).substr(start);
		var endString:String = (length!=0) ? String(string).substr(length) : "";
		replaceString = replacement;
		
		return startString + replaceString + endString;
	}
	
	// Return part of a string
	// http://www.php.net/manual/en/function.substr.php
	// AS3 - String(string).substr(start, length);
	public function substr(string:String, start:int, length:int = 0):String {
		if (length!=0) {
			return string.substr(start, length);
		}
		return string.substr(start);
	}
	
	// Strip whitespace (or other characters) from the beginning and end of a string
	// http://www.php.net/manual/en/function.trim.php
	// AS3 - StringUtil.trim(value);
	public function trim(value:String, charList:String = ""):String {
		return StringUtil.trim(value);
	}
	
	// Make a string's first character uppercase
	// http://www.php.net/manual/en/function.ucfirst.php
	// AS3 - string.substr(0,1).toUpperCase() + string.substr(1);
	public function ucfirst(string:String):String {
		return string.substr(0,1).toUpperCase() + string.substr(1);
	}
	
	// Uppercase the first character of each word in a string
	// http://www.php.net/manual/en/function.ucwords.php
	public function ucwords(string:String):String {
		var array:Array = string.split(' ');
		for (var i:* in array ) {
	 		array[i] = ucfirst( array[i] );
	 	}
		return array.join(' ');
	}
	
	//////////////////////////// VARIABLE HANDLING FUNCTIONS ////////////////////////////
	
	// Determine whether a variable is empty
	// http://www.php.net/manual/en/function.empty.php
	// AS3 - (value==undefined || value==null)
	public function empty(mixed_var:*):Boolean {
	    var key:*;
	    
	    if (mixed_var === ""
	        || mixed_var === 0
	        || mixed_var === "0"
	        || mixed_var === null
	        || mixed_var === false
	        || mixed_var === undefined
	    ){
	        return true;
	    }
	    if (typeof mixed_var == 'object') {
	        for (key in mixed_var) {
	            if (typeof mixed_var[key] !== 'function' ) {
		            return false;
	            }
	        }
	        return true;
	    }
	    return false;

	}
	
	// Get the integer value of a variable
	// http://www.php.net/manual/en/function.intval.php
	// AS3 - int(value);
	public function intval(value:*, base:int = 10):int {
		return int(value);
	}
	
	// Finds out whether a variable is a boolean
	// http://www.php.net/manual/en/function.is-bool.php
	// AS3 - Boolean(value);
	public function is_bool(value:*):Boolean {
		return Boolean(value);
	}
	
	// Verify that the contents of a variable can be called as a function. 
	// This can check that a simple variable contains the name of a valid function, 
	// or that an array contains a properly encoded object and function name. 
	// mixed $var  [, bool $syntax_only  [, string &$callable_name  ]]
	// http://us2.php.net/manual/en/function.is-callable.php
	public function is_callable(variable:*, syntax_only:Boolean = false, callable_name:String = ""):Boolean {
		if (variable is Function) {
			return true;
		}
		return false;
	}
	
	// Finds whether the type given variable is string.
	// mixed $var
	// http://us.php.net/manual/en/function.is-string.php
	public function is_string(variable:*):* {
		return (variable is String) ? true : false;
	}
	
	// Determine whether a variable is set
	// mixed $var  [, mixed $var  [,  $...  ]]
	// http://www.php.net/manual/en/function.isset.php
	public function isset(...args):Boolean {
		
	    var length:int = args.length; 
	    var i:int = 0;
    
	    if (length==0) { 
	        throw new Error('Empty isset'); 
	    }
	    
	    while (i!=length) {
	        if (typeof(args[i])=='undefined' || args[i]===null) { 
	            return false; 
	        } else { 
	            i++; 
	        }
	    }
	    return true;

	}
	
	// Determine whether a variable is set via drill down through the properties
	// instead of this: isset(this.language_data['STYLES']['BRACKETS'][0])
	// you would use this: isset_drilldown(this.language_data,'STYLES','BRACKETS',0)
	// mixed $var [, mixed $property [,  $...  ]]
	// @author Judah Frangipane
	public function isset_drilldown(variable:*, ...properties):Boolean {
		if (variable!=null && variable!=undefined) {
			var length:int = properties.length;
			
			if (properties.length>0) {
				var reference:* = variable;
				
				for (var i:int=0; i<length; i++) {
					var property:String = properties[i];
					if (Object(reference).hasOwnProperty(property)) {
						reference = reference[property];
					}
					else {
						return false;
					}
			    }
			}
			return true;
		}
		else {
			return false;
		}
	}
	
	// Unset a given variable
	// http://www.php.net/manual/en/function.unset.php
	// AS3 - delete value
	public function unset(...args):void {
		for (var item:* in args) {
			item = null;
		}
	}
	
	// Unset a given variable via drill down to property
	// http://www.php.net/manual/en/function.unset.php
	// AS3 - delete value
	public function unset_drilldown(variable:*, ...properties):void {
		if (variable!=null && variable!=undefined) {
			var length:int = properties.length;
			
			if (properties.length>0) {
				var reference:* = variable;
				
				for (var i:int=0; i<length; i++) {
					var property:String = properties[i];
					if (Object(reference).hasOwnProperty(property)) {
						reference = reference[property];
						if (i==length-1) {
							reference = null;
						}
					}
			    }
			    
			}
			else {
				variable = null;
			}
		}
	}
	
	// Finds whether a variable is NULL
	// mixed $var 
	// http://us.php.net/manual/en/function.is-null.php
	public function is_null(variable:*):Boolean {
		if (variable==null || variable==undefined) {
			return true;
		}
		return false;
	}
}
}