package hx.concurrent.internal.externs.java.lang;

@:native("java.lang.Process")
extern class Process {

   /** @since Java 9 */
   public function pid(): haxe.Int64;
}
